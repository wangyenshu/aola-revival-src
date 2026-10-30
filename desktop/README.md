# AolaRuffle (desktop)

A small patch on [MoleRuffle](https://github.com/moleworld-dev/MoleRuffle), the
native Ruffle client built for 摩尔庄园, that makes it an offline 奥拉星 client:

- the boot SWF loads from its original URL, which also spoofs the page URL so
  domain checks in the client pass;
- every request for the original hosts (`www.9aola.com`, `login.9aola.com`,
  `service.9aola.com`, `web.9aola.com`, `aola.100bt.com`, …) is answered from `mirror/` (`src/mirror.rs`), never from the network;
- requests to any other host are blocked unless `AOLA_ALLOW_NETWORK=1`;
- game sockets go to the emulator at 127.0.0.1 on the same port, so the
  original SWF needs no patch;
- 宋体 (SimSun) leads the device-font fallback, as on 2012 Windows.

## Build

```bash
git clone https://github.com/moleworld-dev/MoleRuffle && cd MoleRuffle
git checkout 4049280            # the commit this patch was made against
git apply ../aola-revival/desktop/aolaruffle.patch
cargo run --release -p moleruffle-desktop
```

Linux needs the ALSA headers (`libasound2-dev`). With Rust 1.97 the patched
workspace compiles (`cargo check -p moleruffle-core -p moleruffle-desktop`) and
the navigator's unit tests pass (`cargo test -p moleruffle-core --lib`): mirror
hits incl. query fallback, offline blocking, emulator fallback that keeps the
original URL, and socket redirection. It has not yet run real 2012 files.

## Run

| Variable | Default | Meaning |
| --- | --- | --- |
| `AOLA_MIRROR` | `./mirror` | mirror root from `tools/wayback.py fetch` |
| `AOLA_BOOT_URL` | `http://www.9aola.com/start.swf?120830` | boot SWF's original URL (winter 2012/13 client) |
| `AOLA_PAGE_URL` | `http://www.9aola.com/` | page URL the SWF believes it is embedded in |
| `AOLA_EMULATOR_HOST` | `127.0.0.1` | where game sockets are sent |
| `AOLA_EMULATOR_HTTP` | unset | e.g. `http://127.0.0.1:8080`: mirror misses go to the Node server (emulated pages, miss log) |
| `AOLA_ALLOW_NETWORK` | unset | `1` lets non-original hosts through |

```bash
node server/src/node/main.ts --game 8001 &
AOLA_MIRROR=mirror AOLA_EMULATOR_HTTP=http://127.0.0.1:8080 \
AOLA_BOOT_URL=http://aola.100bt.com/play/<boot>.swf ./target/release/moleruffle
```

`src/mirrorpath.rs` is the Rust twin of `tools/mirrorpath.py`; it tests on its
own with `rustc --edition 2021 --test src/mirrorpath.rs && ./mirrorpath`.
