# Copyright, licences and acknowledgements

## 奥拉星 belongs to 百田

奥拉星 is a web game developed by 广州百田信息科技有限公司 (百田, 100bt.com),
first released in 2010. The game's files, artwork, music, films, text, data
and program code are 百田's. This project is not affiliated with 百田 and
is not endorsed by it.

The repository contains 百田's material for preservation and study. The
GPL licence below does not apply to it, and this project grants no rights
to it.

## Copyright and licence of this project

Copyright (C) the aola-revival contributors.

The work written for this project is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License,
version 3 (SPDX: `GPL-3.0-only`). It is distributed in the hope that it will
be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. The full text is in
[`LICENSE`](LICENSE).

This covers, unless an exception below applies:

- `server/`: the server emulator, the in-page bundle, the service worker,
  the Node server and the tests;
- `web/`: the front end;
- `scripts/`, `tools/` (including `tools/mod-sdk/` and its examples), `tests/`,
  `rebuild/build/` and `.github/`;
- `docs/`, `README.md` and this file;
- the ActionScript in `rebuild/src/` written for this project: files whose
  header says REBUILT, REVIVAL or RECONSTRUCTED and that do not say their code
  was taken from a 百田 module (see below).

## Exceptions

### 百田's material (not GPL)

- `game/`: every game file (SWF, MP3, pictures, the theatre films and the
  WebM/MP4 copies made from them, configuration, the 2013 manifest).
- `rebuild/gen/`: sources generated from 百田's decompiled modules and data
  (NPC conversations, quest tables, the 亚比 dictionary, catalog
  configuration, service interfaces).
- `rebuild/static/`: the `config.xml` overlay and the `revival/*.json`
  tables, which are 百田's data in another form.
- `tools/data/`: the 2013 manifest, live config and catalog files, and the
  lists taken from 百田's world map and quest tables.
- In `rebuild/src/`: code decompiled from 百田's SWFs, used unchanged or
  adapted to the January 2013 libraries. This includes most of `fbteam/`,
  `fbservice/`, `parkour/`, `shoot/`, `shooteffect/`, `spacetime/` and
  `face/`, the scene code of the later scenes in `scenes/`, and every file
  whose header says its code comes from a later or era module ("the later
  copy", "LATER", "decompiled", "era code"). Files in `rebuild/src/` that
  carry no REBUILT, REVIVAL or RECONSTRUCTED header are of this kind. The
  changes this project made to such files are offered under the GPL to the
  extent the contributors hold rights in them; the rest remains 百田's.
- The artwork that the build copies out of 百田's SWFs into the rebuilt
  modules (`tools/swf_transplant.py`), and everything in `build/` and `dist/`
  that comes from `game/`.

The built site (`dist/`) contains 百田's files. Publish it only where you
are allowed to.

### Third-party code

In the repository:

| File | Origin | Licence |
| --- | --- | --- |
| `server/test/e2e/fixtures/WebSocketMain.swf` | web-socket-js by Hiroshi Ichikawa, from the socket.io-client 0.9.16 package | New BSD (see `fixtures/NOTICE.md`) |

Installed by `npm ci` (not in the repository):

| Package | Used for | Licence |
| --- | --- | --- |
| `@ruffle-rs/ruffle` 0.7.1 | the Flash Player emulator; copied into `dist/ruffle/` | MIT or Apache-2.0 |
| `ws` | WebSocket bridge of the Node server | MIT |
| `esbuild` | bundles the emulator and the service worker | MIT |
| `typescript` | type checking | Apache-2.0 |
| `playwright` | automated browser tests | Apache-2.0 |
| `@types/node`, `@types/ws` | type definitions | MIT |

Downloaded by `rebuild/build/setup-toolchain.sh` into `.toolchain/` (not in
the repository; checksums pinned):

| Tool | Used for | Licence |
| --- | --- | --- |
| Apache Royale 0.9.12 (`@apache-royale/royale-js-swf`) | the ActionScript 3 compiler (mxmlc) | Apache-2.0 |
| `playerglobal.swc` 10.1, from github.com/nexussays/playerglobal | the Flash Player 10.1 API to compile against | Adobe's terms for the Flex SDK files |
| JPEXS Free Flash Decompiler 26.4.0 | turns the 2013 libraries into SWCs, edits SWF art | GPL-3.0 (application), LGPL-3.0 (library) |

## Acknowledgements

- **百田 (广州百田信息科技有限公司)** made 奥拉星 and, years later, still kept
  most of its 2010–2013 files on the game's CDN. Without those files there
  would be nothing to revive. 百田's own pages were the main reference for
  what the game was like in 2012: the official site and its guides
  (aola.100bt.com), the 2011 newbie walkthrough, the 奥拉周刊, and the world
  map of November 2012 published on the guide page.
- **Ruffle** (ruffle.rs) runs the Flash content in the browser.
- **The Internet Archive's Wayback Machine** kept the boot files, pages and
  pictures of the January 2013 site that the CDN no longer has.
- **JPEXS Free Flash Decompiler** made it possible to read the 2013 libraries
  and to build against them.
- **Apache Royale** (and the Apache Flex SDK it continues) compiles the
  rebuilt modules; **nexussays/playerglobal** keeps the Flash Player API
  files.
- **Node.js, TypeScript, esbuild, Playwright and Chromium, ws, Python,
  OpenJDK and FFmpeg** are used to build and test the project.
- **Player guide sites of 2010–2013** (among them 7k7k and doyo) recorded the
  rooms, enemies and rewards of the 四大副本 and other content whose server
  data is lost.
- **web-socket-js** (Hiroshi Ichikawa) provides the test fixture of the
  socket pipeline.
