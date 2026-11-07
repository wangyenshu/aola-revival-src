# Development guide

How to build, run and test the revival, how the repository is organised, and
which tools it uses. How the parts work is described in
[IMPLEMENTATION.md](IMPLEMENTATION.md).

## Prerequisites

| Tool | Version | Needed for |
| --- | --- | --- |
| Node.js and npm | 22.18 or newer (CI uses 22) | the emulator, the static build, the tests; runs TypeScript directly |
| Java | 11 or newer (CI uses Temurin 17) | the ActionScript compiler and FFDec |
| Python | 3.10 or newer, standard library only | the build helpers and the data and archive tools |
| A POSIX shell, `curl`, `unzip` | any | `rebuild/build/*.sh` and the toolchain download (Linux, macOS or WSL) |
| Chromium for Playwright | `npx playwright install chromium` | the browser tests only |
| JPEXS FFDec (standalone) | 26.x | regenerating the data in `rebuild/gen` only; the build fetches its own copy |

The first `npm run build:swf` runs `rebuild/build/setup-toolchain.sh`, which
downloads into `.toolchain/` (checksums pinned):

- Apache Royale 0.9.12 (`@apache-royale/royale-js-swf` from npm): the
  `mxmlc` compiler for SWF output;
- `playerglobal.swc` 10.1 (from github.com/nexussays/playerglobal): the
  Flash Player 10.1 API;
- JPEXS Free Flash Decompiler 26.4.0 (from GitHub): makes SWCs of the 2013
  libraries and edits SWF art.

It writes `.toolchain/env.sh`, which exports `ROYALE`, `PLAYERGLOBAL` and
`FFDEC`. Set these variables yourself to use other copies.

## Commands

```bash
npm ci                # install Node packages (Ruffle, esbuild, TypeScript, Playwright, ws)
npm run build:swf     # compile the rebuilt modules into build/rebuilt/
npm run build         # assemble the static site in dist/
npm run serve         # serve dist/ at http://127.0.0.1:8080/
npm test              # unit tests (Node) and tool tests (Python)
npm run check         # TypeScript type check
npm start             # Node dev server (one player): game files, front end, WebSocket bridge, TCP ports
node server/src/node/multi.ts   # the shared server of 联机模式 (docs/MULTIPLAYER.md)
```

`npm run build` options (`scripts/build-static.mjs`):

| Option | Effect |
| --- | --- |
| `--out dir` | output folder (default `dist`) |
| `--rebuilt dir`, `--game dir` | the two file roots (default `build/rebuilt`, `game`) |
| `--exclude a,b` | leave out these top folders of the game files |
| `--copy` | copy the game files instead of hard-linking them (CI uses it) |

`npm run serve` options (`scripts/serve.mjs`): `--dir`, `--port`, `--bind`,
`--base /aola-revival/` (serve under a sub-path, as GitHub Pages does for a
project site) and `--cert`/`--key` (serve https).

## Repository layout

```
.github/workflows/
  pages.yml                   CI: tests, build:swf, build, deploy to GitHub Pages
  gh-pages-branch.yml         run by hand: the same build, force-pushed to the branch gh-pages
LICENSE, NOTICE.md            licence and copyright notes

game/                         百田's game files at their 2013 URLs
  FILES.jsonl                 one line per file: path, size, SHA-1, origin, CDN source, upload date
  www.9aola.com/…             the client (start.swf, loader, modules, scenes, art, music)
  aola.100bt.com/…, web.9aola.com/…   pages and pictures of the 2012–13 site (captures)

rebuild/
  src/<module>/               ActionScript sources, one folder per rebuilt module
  src/shared/                 code compiled into several modules (mmo.revival.*)
  gen/                        sources generated from decompiled modules (committed)
    stubs/                    stand-ins for the lost services (tools/gen_stubs.py)
    tasknpc/, taskdata/       NPC placement, conversations, quest tables
    petdict/, petfight/, petmes/, pmservice/, wildpet/, bconfig/, weekly/   data classes
  static/                     files served as they are
    www.9aola.com/config.xml%3F201301241   the 2013 config.xml with the revival's rooms
    www.9aola.com/revival/    tables the emulator reads (pets, pmdata, tasks, wildpets, materials, theatre)
  build/
    build-swf.sh              the whole SWF build (npm run build:swf)
    setup-toolchain.sh        downloads the compiler tools
    all.sh                    compiles every rebuilt module and installs it at its 2013 URL
    stubs.sh                  compiles the stand-ins
    as3c.sh                   compiles one module against the 2013 libraries
    libs.txt                  the 2013 libraries made into SWCs
    no-stub.txt               modules that must not get a stand-in
    empty-config.xml          compiler configuration

server/
  src/core/                   protocol-independent emulator core (sessions, framing, AMF3, store)
  src/game/sfs2013/           the 2013 game server: protocol, rooms, every game system
  src/game/aola2012.ts, devHandlers.ts   the HTTP endpoints of the 2012 site, test commands
  src/browser/                the in-page bundle, IndexedDB store, service worker
  src/node/                   the Node server
  test/*.test.ts              unit tests (node --test)
  test/e2e/                   browser tests: boot2013.mjs, scenarios/, scenewalk.mjs, fixtures/

web/
  index.html                  the page
  config.js                   settings (boot URL, hosts, socket address, mode, clock)
  boot.js                     starts the service worker, the emulator and Ruffle
  start.js                    what the game's start screens remember and do (单机 / 联机, 选择奥拉)
  saves.js                    what the game's 存档 and 改名字 / 改密码 panels do
  theatre.js                  the page's video functions, which open the game's 百田大剧场
  robots.txt                  asks all crawlers to stay out

scripts/
  build-static.mjs            builds dist/
  serve.mjs                   local static server

tools/                        Python tools (see below), fetch_refs.sh, bootstrap.sh
  data/                       inputs of the tools: the 2013 manifest, live config and catalogs,
                              the 2012 world map's lists, NPC and quest supplements
    game-sources.jsonl        where every file of game/ can be downloaded again
    archive/                  the indexes of the CDN archive (docs/ARCHIVE.md)
  mod-sdk/                    build.mjs (the mod API library, a mod, the examples), embed/, examples/

tests/
  test_tools.py               tests of the Python tools
  mirrorpath-fixtures.json    URL-to-file cases shared by the Python and TypeScript tests

docs/                         documentation
```

Generated and ignored: `node_modules/`, `.toolchain/`, `rebuild/out/`
(intermediate SWFs and SWCs), `build/rebuilt/`, `dist/`, `work/` (test
output).

## The build

### SWF modules (`npm run build:swf`)

`rebuild/build/build-swf.sh`:

1. Loads the toolchain (downloading it if missing).
2. Makes SWCs of the eleven 2013 libraries listed in `libs.txt`
   (`library/common`, `interfaces`, `socketclient`, `materialdata`, the
   loader and others) with `ffdec -swf2swc`, into `rebuild/out/libswc/`.
3. Runs `all.sh`: compiles every module in `rebuild/src` with `as3c.sh`
   (Royale `mxmlc` against `playerglobal.swc`, the library SWCs and, for
   most modules, `rebuild/out/swc/play.swc` made from the rebuilt
   `play.swf`), transplants code into original art where a module keeps its
   art (`tools/swf_transplant.py`), applies the bytecode renames
   (`tools/abc_rename.py`) and the picture fixes (`tools/peticon_fill.py`),
   fixes era files that cannot work as they are (`tools/patch_scripts.py`)
   and cleans the start screen (`tools/clean_start.py`). Each output goes to
   `build/rebuilt/www.9aola.com/<path>%3F<version>`.
4. Runs `stubs.sh`: compiles the stand-ins of `rebuild/gen/stubs` (in
   parallel, `JOBS=4`), except the modules in `no-stub.txt`.
5. Copies `rebuild/static/` into `build/rebuilt/`.
6. Builds the example mods (`tools/mod-sdk/build.mjs examples`) into
   `build/rebuilt/www.9aola.com/revival/mods/` with their `index.json`.

To compile one module while working on it:

```bash
. .toolchain/env.sh
export LIBSWC=rebuild/out/libswc EXTRA_SWC=rebuild/out/swc/play.swc SHARED=rebuild/src/shared
sh rebuild/build/as3c.sh rebuild/src/control mmo/control/DocControl.as rebuild/out/control-code.swf
```

then install the result as `all.sh` does for that module (some modules are
transplanted into art after compiling). `all.sh` is the reference for each
module's main class, extra SWCs and target URL. The play module must be
rebuilt first when engine classes change, because the other modules
compile against `play.swc`.

### Static site (`npm run build`)

`scripts/build-static.mjs`:

1. Copies the front end (`web/`).
2. Bundles the emulator (`server/src/browser/entry.ts` → `emulator.js`)
   and the service worker (`sw.ts` → `sw.js`) with esbuild.
3. Copies Ruffle from `node_modules/@ruffle-rs/ruffle` to `dist/ruffle/`.
4. Hard-links (or copies) the game files into `dist/files/`: `build/rebuilt`
   first, then `game/`, a file of the first root hiding the same path in the
   second; `%` in names becomes `~`. Writes `files/index.json`.

Nothing is downloaded.

### Working without rebuilding `dist/`

`server/test/e2e/boot2013.mjs --mirror build/rebuilt,game` and `npm start`
serve the game files straight from the roots, so a recompiled module is
picked up without running `npm run build`. Only changes to `web/` and
`server/src/` need the static build.

## Tests

### Unit tests

`npm test` runs `node --test server/test/*.test.ts` and
`python3 -m unittest discover -s tests`.

| Test | Covers |
| --- | --- |
| `core.test.ts`, `sfs2013.test.ts`, `node.test.ts` | framing, AMF3, the 2013 protocol, login, rooms, the Node server |
| `pets.test.ts`, `battle.test.ts`, `guardians.test.ts` | 亚比, battles, catching, experience, bosses |
| `tasks.test.ts` | quest progress and server-finished steps |
| `house.test.ts`, `plants.test.ts`, `eggs.test.ts` | the 小屋, trees, eggs |
| `shoot.test.ts`, `parkour.test.ts`, `minigames.test.ts`, `fb.test.ts`, `gyms.test.ts` | 射击, 酷跑星世界, 极限轰炸, the 四大副本, the 道馆 |
| `planetacts.test.ts`, `areafuncs.test.ts`, `yabistudy.test.ts` | the planets' activities, the functions of the places, 亚比融合 and 天赋启迪 |
| `sandbox.test.ts`, `mods.test.ts` | the 沙盒's fights; mods' saved data, 亚比 and gifts |
| `petcards.test.ts`, `petitems.test.ts` | 战术卡, 亚比道具 |
| `multiplayer.test.ts`, `accounts.test.ts`, `cloudflare.test.ts` | a shared server with two players; the page's 奥拉, 改名字, 改密码, 存档; the Cloudflare adapter |
| `tests/test_tools.py` | URL mapping, the archive and game-root tools, `swfinfo`, `add_later`, `gen_tasks` |

### Browser tests

Install Chromium once with `npx playwright install chromium`.
`server/test/e2e/boot2013.mjs` opens the game in Chromium with Ruffle and
records requests, console output, socket traffic and screenshots in the
`--out` folder.

| Option | Effect |
| --- | --- |
| `--out dir` | where to write `console.txt`, `http.txt`, screenshots and `summary.json` |
| `--seconds n` | how long to run |
| `--query dev=1` | page query string; `dev=1` enables the test commands |
| `--actions "38:500,520;46:500,520"` | timed clicks (seconds:x,y); these two click 开始游戏 and log in |
| `--scenario file.mjs` | a module run after the actions, with helpers (`h.hook`, `h.click`, `h.until`, `h.shot`, `h.log`, `h.page`) |
| `--shots 5,15,30` | screenshot times (0 for none) |
| `--mirror roots`, `--dist dir`, `--url url` | serve game files from roots, use another `dist/`, or open a site served elsewhere |
| `--decorated` | keep the page's site decoration (by default the game is shown alone, since tests click by page position) |

The npm scripts run the main scenarios:

| Script | Scenario |
| --- | --- |
| `npm run e2e:newbie` | the whole newbie quest |
| `npm run e2e:story` | the story quests 1214 and 1219 |
| `npm run e2e:garden` | planting in the 家园, the 小屋, a theatre film |
| `npm run e2e:music` | scene music and the music switch |
| `npm run e2e` | the offline pipeline: service worker, Ruffle, the socket proxy (with the web-socket-js fixture) |

Other scenarios: `storysmoke.mjs` (the start conversation of every quest
that begins with an NPC), `stepsmoke.mjs` (the first step of each quest and
the script errors on the way; `STEPS=1`), `storyplay.mjs` (quests played
through, `QUESTS=1742,1750`). `scenewalk.mjs` visits a list of rooms and
records which open and what errors they log.

### The test hook

The browser console shows every socket frame and the engine's log only with
`?verbose=1` (or `?dev=1`); otherwise warnings only, and the page keeps the last
5000 frames (`window.aola.frames`).

With `?dev=1` the control module registers an ExternalInterface callback,
`revival(command, argument)`, which scenarios call through `h.hook`. Useful
commands:

| Command | Returns or does |
| --- | --- |
| `goto room` | load a scene |
| `scene`, `busy`, `pos` | current scene, whether a scene is loading, the player's position |
| `where name`, `origin name`, `bounds name`, `under x,y` | find display objects and what lies under a point |
| `blocked x,y`, `obstruction`, `entrances` | the walkable area and the scene's doors (with whether they can be reached) |
| `talk`, `talk n`, `npc id` | the open conversation, pick a choice, click an NPC |
| `bar name`, `top`, `layers n`, `clearmodal` | press a control bar button, list the top layer or the display tree, close panels |
| `xt Ext.cmd k=v …` | send an extension request |
| `addpet race`, `heal`, `give id`, `tasktest id`, `fight race` | test conveniences (some need the server's dev commands, enabled by `?dev=1`) |
| `mod file`, `modroom` | load and start `revival/mods/<file>` (an example mod), the room a mod shows |

## Conventions

- Keep 2013 behaviour. Use an original file where one survives; when a
  later file must be used, list it in `FILES.jsonl` and adapt it, do not
  bring in later features.
- Mark code with REBUILT, REVIVAL, RECONSTRUCTED, LATER or ERA as described
  in [IMPLEMENTATION.md](IMPLEMENTATION.md), and give the source of every
  reconstructed value.
- Fixes to scenes that are later copies go in `ScenePatches` (or the
  module concerned) rather than into the scene file.
- The build must not download game files. Only the curation tools
  (`tools/add_later.py`, `story_files.py`, `weeklies.py`, `theatre.py`) add
  files to `game/`, and each addition gets a `FILES.jsonl` line with its CDN
  path, upload date and SHA-1. After adding files, run
  `tools/game_sources.py build` (and `check`) so that
  `tools/data/game-sources.jsonl` lists them, and
  `tools/archive_additions.py --meta tools/data/archive …` to add them to
  the archive's indexes.
- Nothing in the front end may load from other sites, and the game must not
  use JavaScript `alert`, `confirm` or `prompt`.
- A new server command is a handler registered with
  `world.xt("Extension.cmd", handler)` in the module of its system, with a
  unit test.

## Tools

All Python tools print their usage with `--help`; the docstring at the top
of each file explains its inputs.

### Game files and the archive

| Tool | Purpose |
| --- | --- |
| `live_archive.py` | find, date and download what remains of the 2010–2013 files on the live CDN |
| `make_aola_archive.py` | rebuild the archive from the live CDN |
| `extract_archive.py` | unpack the archive pieces and verify every file |
| `archive_additions.py` | add the files `game/` took later to the archive's indexes |
| `make_game_root.py` | select the files the revival serves into `game/` and list them in `FILES.jsonl` (`select`), or rebuild `game/` from the list and an archive (`assemble`) |
| `fetch_game.py` | download every file of `game/` again from 百田's CDN and the Wayback Machine, checking each SHA-1 (for a checkout without `game/`) |
| `game_sources.py` | keep `tools/data/game-sources.jsonl`, the download URLs of every file of `game/` (`build`), and check it against `game/FILES.jsonl` (`check`) |
| `bootstrap.sh` | `fetch_game.py`, then `npm ci`, `build:swf` and `build` |
| `add_later.py` | add live CDN copies of files the 2013 client asks for (from the CDN, or `--archive` from a copy of the archive) |
| `story_files.py` | find and add the files the 2012 story quests need |
| `weeklies.py` | add the 奥拉周刊 back issues |
| `theatre.py` | add the theatre films (FLV) and write their list, `revival/theatre.xml` |
| `fetch_refs.sh` | fetch the November 2012 world map from 百田's guide page |
| `wayback.py` | capture 2012-era files from the Wayback Machine |
| `manifest.py` | turn the client's version manifests and code into a list of wanted URLs |
| `pin.py` | pin dynamic URLs to one capture |
| `fill_from_archive.py`, `fill_summary.py` | fill the older mirror roots from the archive, summarise the result |
| `reclassify.py` | re-judge files with the CDN's upload dates |
| `mirrorpath.py` | the URL-to-file rules (shared with TypeScript) |

### Analysis

| Tool | Purpose |
| --- | --- |
| `swfinfo.py` | read compression, format, AS3 and the dates Flash wrote into a SWF |
| `swf_recon.py` | first-pass survey of the client's network code |
| `engine_census.py` | what the surviving code expects from the lost engine classes |
| `module_status.py` | where each 2013 module can come from (original, later copy, lost) |
| `map_pets.py` | read the places, 亚比 and games of the November 2012 world map |

### Data generation

| Tool | Writes |
| --- | --- |
| `gen_stubs.py` | the stand-in services (`rebuild/gen/stubs`) |
| `gen_npc_data.py` | NPC placement and named conversations |
| `gen_tasks.py` | the quest tables and conversations, `revival/tasks.json` |
| `gen_pets.py` | the 亚比 dictionary and species data |
| `gen_pmdata.py` | battle data (`revival/pmdata.json`) |
| `gen_wildpets.py` | wild 亚比 per room |
| `gen_bconfig.py` | the catalog books |
| `gen_materials.py` | prices (`revival/materials.json`) |
| `gen_petmes.py` | the data of the rebuilt `petskillmesservice` |
| `gen_pmservice.py` | the tables of the rebuilt `pmservice` (the 2013 PMCustomData) |
| `config_overlay.py` | the `config.xml` overlay |

These read decompiled modules (made with FFDec) and the files in `game/`;
their docstrings give the exact commands.

### SWF editing (used by the build)

| Tool | Purpose |
| --- | --- |
| `swf_transplant.py` | put compiled code into an original SWF's art |
| `abc_rename.py` | rename a string in a SWF's bytecode |
| `peticon_fill.py` | add missing small pictures to `peticon` files |
| `clean_start.py` | remove the January 2013 campaign from the start screen |
| `patch_scripts.py` | small fixes to era files: a line of a class (FFDec), a named child in a symbol |

### Mods

`tools/mod-sdk/build.mjs` (Node; uses the toolchain of `.toolchain/env.sh`):

| Command | Does |
| --- | --- |
| `node tools/mod-sdk/build.mjs api` | `build/mod-sdk/aola-mod-api.swc`, the library mods compile against, and `aola-mod-embed.swc` (`tools/mod-sdk/embed/`: the base classes of embedded files) |
| `node tools/mod-sdk/build.mjs <folder>` | a mod from its `asconfig.json` |
| `node tools/mod-sdk/build.mjs examples [out]` | the examples of `tools/mod-sdk/examples/` and their `index.json` |

[MODDING.md](MODDING.md) covers writing mods.
