//! Rust twin of tools/mirrorpath.py and server/src/core/mirrorPath.ts:
//! original URL -> relative path inside mirror/. No dependencies, so it can be
//! tested on its own:  rustc --edition 2021 --test mirrorpath.rs && ./mirrorpath

const SAFE_PATH: &[u8] = b"/-_.~!$'()+,;=@";
const SAFE_QUERY: &[u8] = b"-_.~=&";
pub const QUERY_MARK: &str = "%3F";

fn is_unreserved(b: u8) -> bool {
    b.is_ascii_alphanumeric() || matches!(b, b'_' | b'.' | b'-' | b'~')
}

/// Same result as Python's `urllib.parse.quote(s, safe)`.
pub fn quote(s: &str, safe: &[u8]) -> String {
    let mut out = String::with_capacity(s.len());
    for &b in s.as_bytes() {
        if is_unreserved(b) || (b < 0x80 && safe.contains(&b)) {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
    out
}

/// Same result as Python's `urllib.parse.unquote(s)` (UTF-8, errors replaced).
pub fn unquote(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%'
            && i + 2 < bytes.len()
            && bytes[i + 1].is_ascii_hexdigit()
            && bytes[i + 2].is_ascii_hexdigit()
        {
            let hex = std::str::from_utf8(&bytes[i + 1..i + 3]).unwrap_or("00");
            out.push(u8::from_str_radix(hex, 16).unwrap_or(0));
            i += 3;
            continue;
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

struct Split {
    scheme: String,
    host: String,
    port: Option<u16>,
    path: String,
    query: String,
}

fn split(url: &str) -> Option<Split> {
    let url = if url.contains("://") { url.to_string() } else { format!("http://{url}") };
    let (scheme, rest) = url.split_once("://")?;
    let rest = rest.split('#').next().unwrap_or("");
    let end = rest.find(['/', '?']).unwrap_or(rest.len());
    let (netloc, tail) = rest.split_at(end);
    let (path, query) = match tail.split_once('?') {
        Some((p, q)) => (p.to_string(), q.to_string()),
        None => (tail.to_string(), String::new()),
    };
    let hostport = netloc.rsplit('@').next().unwrap_or(netloc);
    let (host, port) = if hostport.starts_with('[') {
        match hostport.find(']') {
            Some(i) => (&hostport[..=i], hostport[i + 1..].strip_prefix(':').and_then(|p| p.parse().ok())),
            None => (hostport, None),
        }
    } else {
        match hostport.rsplit_once(':') {
            Some((h, p)) => (h, p.parse().ok()),
            None => (hostport, None),
        }
    };
    Some(Split {
        scheme: scheme.to_ascii_lowercase(),
        host: host.to_ascii_lowercase(),
        port,
        path,
        query,
    })
}

fn clean_path(raw: &str) -> String {
    let decoded = unquote(if raw.is_empty() { "/" } else { raw }).replace('\\', "/");
    let trailing = decoded.ends_with('/');
    let mut stack: Vec<&str> = Vec::new();
    for seg in decoded.split('/') {
        match seg {
            "" | "." => {}
            ".." => {
                stack.pop();
            }
            s => stack.push(s),
        }
    }
    let mut path = format!("/{}", stack.join("/"));
    if trailing && !path.ends_with('/') {
        path.push('/');
    }
    quote(&path, SAFE_PATH)
}

/// Canonical key: always `http://`, default port dropped, path normalised.
pub fn normalize_url(url: &str) -> Option<String> {
    let u = split(url)?;
    let mut host = u.host.clone();
    if let Some(p) = u.port {
        let default = (u.scheme == "http" && p == 80) || (u.scheme == "https" && p == 443);
        if !default {
            host = format!("{host}:{p}");
        }
    }
    let mut out = format!("http://{host}{}", clean_path(&u.path));
    if !u.query.is_empty() {
        out.push('?');
        out.push_str(&u.query);
    }
    Some(out)
}

/// Relative file path inside the mirror root.
pub fn url_to_relpath(url: &str) -> Option<String> {
    let u = split(&normalize_url(url)?)?;
    let host = match u.port {
        Some(p) => format!("{}_{p}", u.host),
        None => u.host,
    };
    let mut path = u.path;
    if path.ends_with('/') {
        path.push_str("index.html");
    }
    let mut rel = format!("{host}{path}");
    if !u.query.is_empty() {
        rel.push_str(QUERY_MARK);
        rel.push_str(&quote(&u.query, SAFE_QUERY));
    }
    Some(rel)
}

pub fn without_query(rel: &str) -> &str {
    rel.find(QUERY_MARK).map_or(rel, |i| &rel[..i])
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Same cases as tests/mirrorpath-fixtures.json.
    const FIXTURES: &[(&str, &str)] = &[
        ("http://aola.100bt.com/play/start~1.xml", "aola.100bt.com/play/start~1.xml"),
        ("http://AOLA.100bt.com:80/play/Main.swf", "aola.100bt.com/play/Main.swf"),
        ("https://aola.100bt.com:443/play/", "aola.100bt.com/play/index.html"),
        ("http://aola.100bt.com", "aola.100bt.com/index.html"),
        ("http://aola.100bt.com/play/a/./b/../c.swf", "aola.100bt.com/play/a/c.swf"),
        ("http://aola.100bt.com/../../etc/passwd", "aola.100bt.com/etc/passwd"),
        ("http://aola.100bt.com/play/map.swf?v=3", "aola.100bt.com/play/map.swf%3Fv=3"),
        ("http://aola.100bt.com/play/map.swf?v=3&t=a b", "aola.100bt.com/play/map.swf%3Fv=3&t=a%20b"),
        ("http://aola.100bt.com/play/%E4%BA%9A%E6%AF%94.swf", "aola.100bt.com/play/%E4%BA%9A%E6%AF%94.swf"),
        ("http://aola.100bt.com/play/亚比.swf", "aola.100bt.com/play/%E4%BA%9A%E6%AF%94.swf"),
        ("http://aola.100bt.com/play/a:b*c.swf", "aola.100bt.com/play/a%3Ab%2Ac.swf"),
        ("http://service-aola.100bt.com:8080/x.jsp?uid=1", "service-aola.100bt.com_8080/x.jsp%3Fuid=1"),
    ];

    #[test]
    fn matches_shared_fixtures() {
        for (url, rel) in FIXTURES {
            assert_eq!(url_to_relpath(url).as_deref(), Some(*rel), "{url}");
        }
    }

    #[test]
    fn strips_query_mark() {
        assert_eq!(without_query("a/b.swf%3Fv=1"), "a/b.swf");
        assert_eq!(without_query("a/b.swf"), "a/b.swf");
    }
}
