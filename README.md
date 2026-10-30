# aola-revival

奥拉星 (Aola Star) as it was in January 2013, playable in a browser: the
original client SWFs of the 2013-01-25 release, served at their original
`www.9aola.com` URLs, running in Ruffle (WebAssembly) against a server
emulator that runs in the page. Where the 2013 code is lost, it is rebuilt in
ActionScript 3 against the surviving 2013 libraries, and every rebuilt file
says so.

This repository holds everything needed to build it, the archived game files
included, and builds a static site that any static host can serve, GitHub
Pages included. Building downloads only tools (npm packages, playerglobal,
FFDec), never game files.

The game files in `game/`, and the data derived from them in `rebuild/gen`
and `rebuild/static`, are 百田's. Keep this repository private and do not
redistribute them.

## Build

Needs Node 22.18 or newer, Java 11 or newer (17 is what CI uses), Python 3,
`curl` and `unzip`. The SWF build is a shell script: Linux, macOS, or WSL on
Windows.

```bash
npm ci
npm run build:swf   # rebuilt SWF modules -> build/rebuilt/ (about 3 minutes)
npm run build       # static site -> dist/ (about 920 MB)
npm run serve       # http://127.0.0.1:8080/
```

The first `build:swf` fetches the build tools into `.toolchain/`
(`rebuild/build/setup-toolchain.sh`, checksums pinned): Apache Royale 0.9.12
(the ActionScript compiler, from npm), `playerglobal.swc` 10.1 and JPEXS FFDec
26.4.0 (from GitHub). It then makes SWCs of the eleven 2013 libraries in
`game/` (`rebuild/build/libs.txt`), compiles the rebuilt modules
(`rebuild/build/all.sh`) and the generated stand-ins for lost services
(`rebuild/build/stubs.sh`), and adds `rebuild/static/`.

`npm run build` (`scripts/build-static.mjs`) writes `dist/`:

| In dist/ | What |
| --- | --- |
| `index.html`, `config.js`, `boot.js` | the front end (`web/`) |
| `emulator.js` | the 2013 server emulator, run in the page (`server/src/browser`) |
| `sw.js` | the service worker that answers requests for the original hosts |
| `ruffle/` | Ruffle 0.7.1 (npm `@ruffle-rs/ruffle`) |
| `files/` | the game files: `build/rebuilt` above `game/`, a file the first answers for left out; `%` in names becomes `~`; `files/index.json` lists them |

Open the page from `http://127.0.0.1`, `http://localhost` or `https://`
(service workers need one of these). Click 开始游戏; you log in as 小奥拉 and
arrive in 奥拉广场. Progress is kept in the browser (IndexedDB), per site.

## Publish on GitHub Pages

1. Push this repository to GitHub. It is about 920 MB; no file is over 20 MB.
2. Settings → Pages → Build and deployment → Source: **GitHub Actions**.
3. Push to `main` (or run the workflow by hand). `.github/workflows/pages.yml`
   runs the tests, `build:swf` and `build`, and deploys `dist/`; the site is at
   `https://<user>.github.io/<repo>/`.

GitHub Pages from a private repository needs a paid plan (Pro, Team or
Enterprise), and the published site is public to anyone with its address,
even when the repository is private; only GitHub Enterprise Cloud can make a
Pages site private. Pages publishes at most 1 GB: `npm run build -- --exclude
activityres,game` leaves out whole folders if the site grows past it.

On an https page the browser would block the game's `http://` requests before
the service worker sees them, so `boot.js` asks for the original hosts over
https there (and tells Ruffle to do the same); the service worker answers
both. It also gives each file its content type, which a static host cannot
tell from a name like `aola.js~3F20121227`.

## game/

17,186 files (1,108 MB) at the paths the January 2013 client asks for:
`www.9aola.com/<path>%3F<version>`, the version being the one in the
2013-01-25 manifest or the loader's default `1210`.

`game/FILES.jsonl` lists every file with its size, SHA-1 and origin:

| Origin | Files | What |
| --- | --: | --- |
| `era` | 13,305 | from the live-CDN archive of 28 October 2026, uploaded on or before the release date: the files the 2013 client loaded, or older unchanged ones; 248 of them taken later, which the archive's first pass had not asked for: 22 shop book pages and the 8 trees of the 家园 (`plant/y000001–8`, June 2012) with `tools/add_later.py`, 217 films, comics and panels of the 2012 story quests (`tools/story_files.py`), the 奥拉星2周年 film of the 百田大剧场 (`tools/theatre.py`) |
| `later` | 3,737 | uploaded after the release: used only where nothing older survives, and only what the 2013 client asks for (listed in the manifest or the config, the 亚比, NPCs, tasks and furniture of the 2013 ranges by number); 291 of them (`"added": "story quests…"`) for the 2012 story quests: scenes the 2013 client no longer had, the scripts that survive only as their 2015–2019 uploads (`tools/story_files.py`) and the fight art of two task 亚比; with `tools/add_later.py`: 2 the HELLO's look, 51 shop book pages (道具, 家具, 种植, 射击卡), 6 the 形象卡's bare body; the 战队 film at its December 2012 address (a May 2013 upload, `tools/theatre.py`) |
| `derived` | 6 | made here from a file above: the two films of the 百田大剧场 as WebM and MP4 (a page cannot play Flash video) and a frame of each (`tools/theatre.py`) |
| `capture` | 138 | not on the CDN any more: Wayback Machine captures of the boot chain and pages, the November 2012 map from 百田's guide page |

It was made from the archive (`docs/ARCHIVE.md`) and earlier captures with
`tools/make_game_root.py select` (rules and lists in `tools/data/`), and the
files added since with `tools/story_files.py --fetch`, `tools/add_later.py` and
`tools/theatre.py` (the only tools that download into `game/`; building never does). The same
folder can be made again from `FILES.jsonl` and a local copy of the archive,
every SHA-1 checked, nothing downloaded (the files added since are not in the
archive: give a copy of `game/` as a search folder):

```bash
python3 tools/make_game_root.py assemble --files game/FILES.jsonl \
    --archive aola_archive_2013 --search <older folders holding captures> --out game
```

## Developing

- **ActionScript**: sources in `rebuild/src` (one folder per module, shared
  code in `rebuild/src/shared`). `npm run build:swf` rebuilds all of them; to
  build one, `. .toolchain/env.sh` and call `rebuild/build/as3c.sh` as
  `all.sh` does. `rebuild/gen` holds sources generated once from the
  decompiled 2013 libraries (`tools/gen_stubs.py` for the stand-ins,
  `tools/gen_npc_data.py`, `gen_tasks.py`, `gen_pets.py`, `gen_bconfig.py`,
  `gen_wildpets.py` for data); `rebuild/static` holds the `config.xml` overlay
  (`tools/config_overlay.py`) and the 亚比, skill and item tables the emulator
  reads (`tools/gen_pmdata.py`, `gen_pets.py`, `gen_materials.py`,
  `gen_wildpets.py`). They are committed so that building needs no decompiler.
- **Emulator** (TypeScript, `server/src`): `npm test` runs the unit tests (and
  the Python ones in `tests/`), `npm run check` the type check.
- **In the browser**: `npx playwright install chromium` once, then
  `npm run e2e:newbie` plays the whole newbie quest in Chromium against
  `dist/` and leaves screenshots in `work/e2e-newbie/`; `npm run e2e:story`
  plays the story quests 1214 and 1219 (`work/e2e-story/`), `npm run e2e:music`
  listens to the scene music and the music switch (`work/e2e-music/`),
  `npm run e2e:garden` plants a tree in the 家园, goes into the 小屋 and plays a
  film of the 百田大剧场 (`work/e2e-garden/`).
  The scenarios `storysmoke.mjs` (every start conversation), `stepsmoke.mjs`
  (the conversation of each step, and the errors the scripts throw) and
  `storyplay.mjs` (quests played through, `QUESTS=1742,1750`) look at the
  story quests at large.
  `server/test/e2e/boot2013.mjs --mirror build/rebuilt,game` serves the game
  files straight from the roots (no `npm run build` after changing a module);
  `--url` tests a site served elsewhere, such as `npm run serve -- --base
  /aola/` or the published Pages site.
- **Node server** (`npm start`): serves `dist/` and the roots over HTTP with a
  WebSocket bridge and optional raw TCP game ports, for several players or the
  native Ruffle client in `desktop/`.

## What is rebuilt, and how faithful it is

- **Engine** (`rebuild/src/control`): `mmo.play.*` written to the API the 392
  surviving era SWFs use. `tools/engine_census.py` lists every member they
  touch, with the exact override signatures and namespaces they need.
- **奥拉广场** (`rebuild/src/scenes/starland`): the January 2013 square is lost
  (the live file is a later redesign). The art is the July 2012 square kept in
  `bigscene/starlandcopy.swf`, bound to rebuilt code by `tools/swf_transplant.py`.
- **Services**: for each service whose module is lost, `tools/gen_stubs.py`
  generated a class with the original name and interface. Every method returns
  an empty value and logs its first call (`[rebuilt] stub called: …` in the
  browser console), which shows what to rebuild next.
- **Server** (`server/src/game/sfs2013`): the 2013 room protocol (login, rooms,
  user variables, extension calls in AMF3), the startup replies, 亚比 and
  battles, items and shops, the home, tasks. Rules the client never knew
  (damage, catch rates, rewards) are RECONSTRUCTED and say where from.

Working now: the newbie quest of 2012 from the HELLO's first call to
麦哲伦's ceremony (choosing the first 亚比, the first fight, buying 亚比球,
catching a 朵朵兔, getting the HELLO, with the era task panels and films);
after it, the 162 story quests of 2010–12 under 可接 in the task panel
(猫王子, 思伍德, 烈焰鸟, 巨人山脉, 幽暗冥州, 钻石岛, 美食之星, 童话之星, 糖果星,
骑士学院, 尖叫游乐园, 白灵圣殿 …) running their own scripts, the first two of
巨人山脉 checked from start to end; the
world map (the November 2012 map), NPCs with their talk and the NPC
challenges (异星使者维克 and ten others), each scene's music, walking round
obstacles (A* on the scene's obstruction), the HELLO walking behind the player,
the control bar of December 2011 (phrases, faces, actions, 射击 with the
shoot cards and their effects, chat log, 奥拉周刊, music switch, 商城), the
shop books (道具, 射击卡, 服装, 家具, 种植, the 收费 books of the 商城), the
player card with the wardrobe, the pet bag and the following 亚比, the
亚比仓库, the 家园 of 2012 (rebuilt from its tutorial picture: trees to plant,
water, feed and pick in its 植树盆) with 我的家, the home with furniture and
storage, the 百田大剧场 (the 奥拉星 films that survive), the start screen
without the January 2013 campaign, a 工具箱 on the control bar (晶币, 星币,
晶豆, experience, any 亚比 by number; not of 2013), gathering in scenes, the wild and rare 亚比 the
November 2012 map lists for each place, battles, and the mini games (their
entrance panels, the games' own SWFs, 晶币 for the score). Known gaps: the
HELLO's panel, bosses and arenas, friends, daily tasks and most activities
are still stand-ins (clicking one says 这个功能还在修复中). `docs/PLAN.md` lists every
missing system, what survives of it, the server commands it needs, and the
milestone order.

## Layout

```
game/       the archived game files (see above) and FILES.jsonl
rebuild/    AS3 sources (src/), generated sources (gen/), static data (static/), build scripts (build/)
server/     emulator (TypeScript): 2013 protocol, in-page bundle, service worker, Node server, tests
web/        front end: page, boot script, settings
scripts/    build-static.mjs (dist/), serve.mjs (local static server)
tools/      archive, dating, data generation and SWF tools (Python 3)
tests/      Python tests and the URL-mapping fixtures shared by Python, TypeScript and Rust
docs/       PLAN.md (state and plan), ARCHIVE.md (the CDN archive)
desktop/    AolaRuffle: patch turning MoleRuffle (native Ruffle) into an offline client
```
