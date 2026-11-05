# aola-revival

A playable reconstruction of the web game 奥拉星 (Aola Star) as it was in
January 2013.

The original client SWFs of the 25 January 2013 release run in
[Ruffle](https://ruffle.rs) in the browser. A server emulator written in
TypeScript runs in the same page and answers the client with the 2013
protocol. Client modules that did not survive are rebuilt in ActionScript 3
against the surviving 2013 libraries and compiled into SWFs. The result is a
static website (单机模式: the server runs in the page, progress is saved in
the browser) that can also connect to a shared server you run yourself
(联机模式, [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md)).

The repository contains the archived game files (`game/`), the rebuilt
sources and everything needed to build the site. Building downloads build
tools only, never game files.

## Status

Playable: the newbie quest and 182 other quests of 2010–2013, NPCs
in every place of the November 2012 world map, wild 亚比, battles and
catching, the 守护者 and event bosses, the 四大副本, 85 mini games, shops,
the 小屋, 家园 and 动物园, the 亚比孵化器, riding, 射击, the 奥拉周刊 back
issues and more. See [docs/FEATURES.md](docs/FEATURES.md) for the full lists.

With other players, on a shared server: 好友, 组队 (up to 3), visiting homes,
chat, 射击, 亚比对战, mods together. Not available: 战队, 兵团, trading, team
battles, daily tasks, the HELLO's own panel and most time-limited activities.
Their buttons show 这个功能还在修复中.

Additions that were not in the 2013 game: the 工具箱 (currencies, any 亚比,
teleport, save export) and the 沙盒 (custom battles, and mods written in
ActionScript 3 that add rooms, characters, animations and 亚比). See
[docs/GUIDE.md](docs/GUIDE.md).

## Quick start

Requirements: Node.js 22.18 or newer, Java 11 or newer, Python 3, `curl` and
`unzip`, on Linux, macOS or WSL.

```bash
npm ci
npm run build:swf   # compile the rebuilt modules into build/rebuilt/
npm run build       # assemble the site in dist/ (about 1.4 GB)
npm run serve       # serve dist/ at http://127.0.0.1:8080/
```

The first `build:swf` downloads the compiler tools into `.toolchain/`. Open
the page from `http://127.0.0.1`, `http://localhost` or an `https://`
address; the page needs a service worker, which browsers allow only there.
Click 开始游戏, choose 单机模式 and 进入, then make an 奥拉 on the 选择奥拉
screen (新建奥拉, up to three a browser): the newbie quest starts.

[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) describes the build in detail.

## Getting the game files

A checkout without `game/` can download 百田's files again:

```bash
python3 tools/fetch_game.py        # download game/ from 百田's CDN and the Wayback Machine
sh tools/bootstrap.sh              # the same, then npm ci, build:swf and build
```

`tools/fetch_game.py` reads `tools/data/game-sources.jsonl`, which gives the
download URLs of every file and its SHA-1; a file is kept only if it matches.
百田 replaces files on its CDN from time to time; files that no
longer match are listed in `work/fetch-game-report.json`, and
`--keep-changed` keeps the newer copies instead. The whole archive
(more files than the game uses) can be downloaded with
`python3 tools/make_aola_archive.py --out aola_archive_2013`, from the
indexes in `tools/data/archive/`.

## Deploying

`dist/` can be served by any static web host.

For GitHub Pages, the workflow `.github/workflows/pages.yml` runs the tests,
builds the modules and the site, and deploys `dist/` on every push to `main`.
Enable it under Settings → Pages → Build and deployment → Source: GitHub
Actions. The site is then at `https://<user>.github.io/<repo>/`.

To serve the site from a branch instead, run the workflow
`.github/workflows/gh-pages-branch.yml` by hand (Actions → "Build and
publish to gh-pages" → Run workflow). It creates the branch `gh-pages` if
there is none, builds the site as `pages.yml` does, and force-pushes `dist/`
there as a single commit, replacing whatever the branch held. Then choose
Source: Deploy from a branch, `gh-pages`, `/ (root)`. Each run uploads the
whole site (about 1.4 GB).

To leave folders of game files out of the site, pass them to the build:
`npm run build -- --exclude activityres,weekly`.

Notes:

- The page asks the original hosts (`www.9aola.com` and others) for every
  file; the service worker answers from `dist/files/`. On an `https` page the
  requests are made over `https`, so the browser does not block them as mixed
  content.
- Nothing is loaded from other sites: Ruffle, the emulator and all pictures
  are part of the site, and Ruffle is set to open no links.
- `robots.txt` and a robots meta tag ask all crawlers, including AI crawlers,
  to stay out. Crawlers read `robots.txt` only at the root of a host, so on a
  project site it applies only if the same file is served at the root.

## Documentation

| Document | Contents |
| --- | --- |
| [docs/GUIDE.md](docs/GUIDE.md) | Playing: controls, saves, the 工具箱 (including the 亚比 marked 无法获得) and the 沙盒 |
| [docs/FEATURES.md](docs/FEATURES.md) | What is supported: places and NPCs, quests, bosses, the 四大副本, mini games, other systems, known gaps |
| [docs/IMPLEMENTATION.md](docs/IMPLEMENTATION.md) | How it works: the page, the emulator, the rebuilt client, each subsystem |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Building, testing, the folder structure, the tools |
| [docs/MULTIPLAYER.md](docs/MULTIPLAYER.md) | 联机模式: running a shared server (Node or Cloudflare), accounts, saves and passwords, what works together |
| [docs/MODDING.md](docs/MODDING.md) | Writing mods for the 沙盒: building with Apache Royale or VS Code, the API, the examples |
| [docs/ARCHIVE.md](docs/ARCHIVE.md) | The archive of the game's CDN that `game/` was made from |

## Repository layout

```
game/       archived game files at their 2013 URLs, listed in game/FILES.jsonl
rebuild/    ActionScript sources (src/), generated sources (gen/), data (static/), build scripts (build/)
server/     the server emulator, the in-page bundle, the service worker, the Node and Cloudflare servers, tests
web/        the page, its boot script and settings, the page's side of the start screens and save panels
scripts/    build-static.mjs (builds dist/), serve.mjs (local static server)
tools/      archive, data generation and SWF tools (Python), the mod SDK
tests/      Python tests and shared fixtures
docs/       documentation
```

## Acknowledgements

奥拉星 was made by 百田 (广州百田信息科技有限公司). This project depends on
the files 百田 kept on its CDN and on its official pages and guides, on
Ruffle, the Internet Archive's Wayback Machine, JPEXS Free Flash Decompiler
and Apache Royale, and on the player guide sites of 2010–2013. The full list
is in [NOTICE.md](NOTICE.md).

## Copyright and licence

The code and documentation written for this project are copyright the
aola-revival contributors and licensed under the GNU General Public License
version 3 ([LICENSE](LICENSE)).

The game itself is 百田's. The files in `game/`, the data derived from them
in `rebuild/gen/`, `rebuild/static/` and `tools/data/`, and the code taken
from 百田's SWFs in `rebuild/src/` are not covered by the GPL and remain
百田's. Third-party code keeps its own licence. [NOTICE.md](NOTICE.md) lists
exactly what is covered and what is not. Do not redistribute 百田's files.
