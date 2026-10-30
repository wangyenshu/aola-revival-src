//! AolaRuffle: serve the original hosts from the frozen mirror and send game
//! sockets to the local emulator. Replaces MoleRuffle's CachingNavigator.
//!
//! - fetch for an original host (aola.100bt.com, …) is answered from
//!   `<mirror>/<relpath>`; never from the network. A miss goes to the
//!   emulator's `/__original?url=` endpoint when `AOLA_EMULATOR_HTTP` is set
//!   (emulated login/.jsp pages + the miss log), otherwise it is a 404.
//! - fetch for any other host is blocked unless `AOLA_ALLOW_NETWORK=1`.
//! - connect_socket(host, port) is rewritten to `AOLA_EMULATOR_HOST`
//!   (default 127.0.0.1) at the same port, so the original SWF needs no patch.

use std::borrow::Cow;
use std::path::PathBuf;
use std::time::Duration;

use async_channel::{Receiver, Sender};
use encoding_rs::Encoding;
use indexmap::IndexMap;
use ruffle_core::backend::navigator::{
    ErrorResponse, NavigationMethod, NavigatorBackend, OwnedFuture, Request, SuccessResponse,
};
use ruffle_core::loader::Error;
use ruffle_core::socket::{SocketAction, SocketHandle};
use url::{ParseError, Url};

use crate::mirrorpath::{url_to_relpath, without_query};

/// Hosts whose content lives in the mirror.
pub const ORIGINAL_HOSTS: &[&str] = &[
    "www.9aola.com",
    "web.9aola.com",
    "login.9aola.com",
    "service.9aola.com",
    "aola.100bt.com",
    "www.100bt.com",
    "service-aola.100bt.com",
];

#[derive(Clone, Debug)]
pub struct EmulatorConfig {
    /// Host the game sockets are redirected to.
    pub socket_host: String,
    /// Base URL of the Node server, for emulated HTTP endpoints (optional).
    pub http_base: Option<String>,
    /// Let requests to non-original hosts through (off: fully offline).
    pub allow_network: bool,
}

impl EmulatorConfig {
    pub fn from_env() -> Self {
        Self {
            socket_host: std::env::var("AOLA_EMULATOR_HOST").unwrap_or_else(|_| "127.0.0.1".into()),
            http_base: std::env::var("AOLA_EMULATOR_HTTP").ok().filter(|s| !s.is_empty()),
            allow_network: std::env::var("AOLA_ALLOW_NETWORK").is_ok_and(|v| v == "1"),
        }
    }
}

/// Mirror root: `AOLA_MIRROR`, else `./mirror` next to the working directory.
pub fn mirror_dir() -> PathBuf {
    std::env::var_os("AOLA_MIRROR")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("mirror"))
}

pub struct MirrorNavigator<N> {
    inner: N,
    mirror: PathBuf,
    cfg: EmulatorConfig,
}

impl<N> MirrorNavigator<N> {
    pub fn new(inner: N, mirror: PathBuf, cfg: EmulatorConfig) -> Self {
        tracing::info!("mirror: {} | sockets -> {} | http fallback: {:?}", mirror.display(), cfg.socket_host, cfg.http_base);
        Self { inner, mirror, cfg }
    }

    fn lookup(&self, url: &str) -> Option<(String, Vec<u8>)> {
        let rel = url_to_relpath(url)?;
        for candidate in [rel.as_str(), without_query(&rel)] {
            if candidate.split('/').any(|seg| seg == "..") {
                return None;
            }
            let path = self.mirror.join(candidate);
            if let Ok(bytes) = std::fs::read(&path) {
                return Some((candidate.to_string(), bytes));
            }
        }
        None
    }
}

fn is_original(url: &str) -> bool {
    Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| ORIGINAL_HOSTS.contains(&h.to_ascii_lowercase().as_str())))
        .unwrap_or(false)
}

fn not_found(url: String) -> OwnedFuture<Box<dyn SuccessResponse>, ErrorResponse> {
    Box::pin(async move {
        let error = Error::HttpNotOk("not in mirror".into(), 404, false, 0);
        Err(ErrorResponse { url, error })
    })
}

impl<N: NavigatorBackend> NavigatorBackend for MirrorNavigator<N> {
    fn fetch(&self, request: Request) -> OwnedFuture<Box<dyn SuccessResponse>, ErrorResponse> {
        let url = request.url().to_string();
        if is_original(&url) {
            // Static files answer any method, as the original web servers did.
            if let Some((rel, bytes)) = self.lookup(&url) {
                tracing::debug!("mirror 200 {url} -> {rel}");
                return Box::pin(async move { Ok(Box::new(MirrorResponse::new(url, bytes)) as Box<dyn SuccessResponse>) });
            }
            if let Some(base) = &self.cfg.http_base {
                let target = format!(
                    "{}/__original?url={}",
                    base.trim_end_matches('/'),
                    url::form_urlencoded::byte_serialize(url.as_bytes()).collect::<String>()
                );
                tracing::info!("mirror miss, asking emulator: {url}");
                let mut fwd = Request::request(request.method(), target, request.body().clone());
                fwd.set_headers(request.headers().clone());
                let inner = self.inner.fetch(fwd);
                // Keep the original URL so loaderInfo.url and relative loads stay authentic.
                return Box::pin(async move {
                    let mut resp = inner.await.map_err(|e| ErrorResponse { url: url.clone(), error: e.error })?;
                    resp.set_url(url);
                    Ok(resp)
                });
            }
            tracing::warn!("mirror 404 {url}");
            return not_found(url);
        }
        if self.cfg.allow_network {
            return self.inner.fetch(request);
        }
        tracing::warn!("blocked (offline mode): {url}");
        not_found(url)
    }

    fn navigate_to_url(&self, url: &str, target: &str, vars: Option<(NavigationMethod, IndexMap<String, String>)>) {
        // Links out of the game (recharge pages, forums): the inner navigator only logs them.
        tracing::info!("navigate_to_url: {url} ({target})");
        self.inner.navigate_to_url(url, target, vars)
    }

    fn resolve_url(&self, url: &str) -> Result<Url, ParseError> {
        self.inner.resolve_url(url)
    }

    fn spawn_future(&mut self, future: OwnedFuture<(), Error>) {
        self.inner.spawn_future(future)
    }

    fn pre_process_url(&self, url: Url) -> Url {
        self.inner.pre_process_url(url)
    }

    fn connect_socket(
        &mut self,
        host: String,
        port: u16,
        timeout: Duration,
        handle: SocketHandle,
        receiver: Receiver<Vec<u8>>,
        sender: Sender<SocketAction>,
    ) {
        tracing::info!("socket {host}:{port} -> {}:{port}", self.cfg.socket_host);
        let to = self.cfg.socket_host.clone();
        self.inner.connect_socket(to, port, timeout, handle, receiver, sender)
    }
}

/// A file from the mirror presented as an HTTP 200 for its original URL.
struct MirrorResponse {
    url: String,
    bytes: Vec<u8>,
    chunk_done: bool,
}

impl MirrorResponse {
    fn new(url: String, bytes: Vec<u8>) -> Self {
        Self { url, bytes, chunk_done: false }
    }
}

impl SuccessResponse for MirrorResponse {
    fn url(&self) -> Cow<'_, str> {
        Cow::Borrowed(&self.url)
    }

    fn set_url(&mut self, url: String) {
        self.url = url;
    }

    fn body(self: Box<Self>) -> OwnedFuture<Vec<u8>, Error> {
        let bytes = self.bytes;
        Box::pin(async move { Ok(bytes) })
    }

    fn text_encoding(&self) -> Option<&'static Encoding> {
        None
    }

    fn status(&self) -> u16 {
        200
    }

    fn redirected(&self) -> bool {
        false
    }

    fn next_chunk(&mut self) -> OwnedFuture<Option<Vec<u8>>, Error> {
        if self.chunk_done {
            Box::pin(async { Ok(None) })
        } else {
            self.chunk_done = true;
            let bytes = std::mem::take(&mut self.bytes);
            Box::pin(async move { Ok(Some(bytes)) })
        }
    }

    fn expected_length(&self) -> Result<Option<u64>, Error> {
        Ok(Some(self.bytes.len() as u64))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::rc::Rc;

    /// Stand-in for ExternalNavigatorBackend that records what reaches it.
    #[derive(Clone, Default)]
    struct Stub {
        seen: Rc<RefCell<Vec<String>>>,
    }

    impl NavigatorBackend for Stub {
        fn fetch(&self, request: Request) -> OwnedFuture<Box<dyn SuccessResponse>, ErrorResponse> {
            let url = request.url().to_string();
            self.seen.borrow_mut().push(format!("fetch {url}"));
            Box::pin(async move { Ok(Box::new(MirrorResponse::new(url, b"from-emulator".to_vec())) as Box<dyn SuccessResponse>) })
        }
        fn navigate_to_url(&self, url: &str, _: &str, _: Option<(NavigationMethod, IndexMap<String, String>)>) {
            self.seen.borrow_mut().push(format!("navigate {url}"));
        }
        fn resolve_url(&self, url: &str) -> Result<Url, ParseError> {
            Url::parse(url)
        }
        fn spawn_future(&mut self, _future: OwnedFuture<(), Error>) {}
        fn pre_process_url(&self, url: Url) -> Url {
            url
        }
        fn connect_socket(
            &mut self,
            host: String,
            port: u16,
            _timeout: Duration,
            _handle: SocketHandle,
            _receiver: Receiver<Vec<u8>>,
            _sender: Sender<SocketAction>,
        ) {
            self.seen.borrow_mut().push(format!("socket {host}:{port}"));
        }
    }

    fn mirror(tag: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("aolaruffle-test-{}-{tag}", std::process::id()));
        std::fs::create_dir_all(dir.join("aola.100bt.com/play")).unwrap();
        std::fs::write(dir.join("aola.100bt.com/play/Main.swf"), b"FWS-main").unwrap();
        std::fs::write(dir.join("aola.100bt.com/play/map.swf%3Fv=3"), b"map-v3").unwrap();
        dir
    }

    fn body(nav: &MirrorNavigator<Stub>, url: &str) -> Result<(String, Vec<u8>), u16> {
        futures::executor::block_on(async {
            match nav.fetch(Request::get(url.to_string())).await {
                Ok(resp) => {
                    let final_url = resp.url().to_string();
                    Ok((final_url, resp.body().await.unwrap()))
                }
                Err(e) => match e.error {
                    Error::HttpNotOk(_, status, _, _) => Err(status),
                    _ => Err(0),
                },
            }
        })
    }

    #[test]
    fn serves_original_hosts_from_the_mirror_only() {
        let stub = Stub::default();
        let cfg = EmulatorConfig { socket_host: "127.0.0.1".into(), http_base: None, allow_network: false };
        let nav = MirrorNavigator::new(stub.clone(), mirror("serve"), cfg);
        assert_eq!(body(&nav, "http://aola.100bt.com/play/Main.swf").unwrap().1, b"FWS-main");
        assert_eq!(body(&nav, "http://aola.100bt.com/play/map.swf?v=3").unwrap().1, b"map-v3");
        assert_eq!(body(&nav, "http://aola.100bt.com/play/Main.swf?v=99").unwrap().1, b"FWS-main");
        assert_eq!(body(&nav, "http://aola.100bt.com/play/gone.swf"), Err(404));
        assert_eq!(body(&nav, "http://example.com/tracker.js"), Err(404));
        assert!(stub.seen.borrow().is_empty(), "nothing reached the network: {:?}", stub.seen.borrow());
    }

    #[test]
    fn misses_go_to_the_emulator_and_keep_their_original_url() {
        let stub = Stub::default();
        let cfg = EmulatorConfig {
            socket_host: "127.0.0.1".into(),
            http_base: Some("http://127.0.0.1:8080".into()),
            allow_network: false,
        };
        let nav = MirrorNavigator::new(stub.clone(), mirror("miss"), cfg);
        let (url, bytes) = body(&nav, "http://aola.100bt.com/play/login.jsp?u=1").unwrap();
        assert_eq!(bytes, b"from-emulator");
        assert_eq!(url, "http://aola.100bt.com/play/login.jsp?u=1");
        assert_eq!(
            stub.seen.borrow().as_slice(),
            ["fetch http://127.0.0.1:8080/__original?url=http%3A%2F%2Faola.100bt.com%2Fplay%2Flogin.jsp%3Fu%3D1"]
        );
    }

    #[test]
    fn sockets_are_redirected_to_the_emulator() {
        let stub = Stub::default();
        let cfg = EmulatorConfig { socket_host: "127.0.0.1".into(), http_base: None, allow_network: false };
        let mut nav = MirrorNavigator::new(stub.clone(), mirror("socket"), cfg);
        let (_tx, rx) = async_channel::unbounded();
        let (tx2, _rx2) = async_channel::unbounded();
        nav.connect_socket("118.123.4.5".into(), 8001, Duration::from_secs(5), SocketHandle::default(), rx, tx2);
        assert_eq!(stub.seen.borrow().as_slice(), ["socket 127.0.0.1:8001"]);
    }
}
