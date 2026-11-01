# 奥拉星 live CDN archive, 28 October 2026

Everything the live game server (`http://aola.100bt.com/play/`) still served
from 2010–2013 on 28 October 2026, saved byte for byte, plus a dated list of
every path that was asked.

## Layout

| Path | What |
| --- | --- |
| `aola.100bt.com/play/…` | 18,403 files whose upload date (`Last-Modified`) is 2010–2013: 377 from 2010, 4,293 from 2011, 7,854 from 2012, 5,879 from 2013. 1,719 MB. Same paths as on the server. |
| `index.jsonl` | One line per file: path, upload date, ETag, size, SHA-1, SWF format, the SWF's own embedded (XMP) date. |
| `_later/aola.100bt.com/play/…` | 7,213 files that 2012/13 code, manifests or configs refer to, but whose live copy was uploaded in 2014 or later (651 MB). Of the first 5,843, by their own embedded dates: 62 still hold 2012/13 content (re-uploaded unchanged, mostly on 17 Oct 2024), 4,448 are later versions, 1,333 carry no date (503 of them in the old Flash format). A later pass added the battle sprites `fightassets/pet<n>.swf` of every 亚比 of the era (1,483 files, 91 MB): all were re-exported and uploaded again in December 2015 – January 2016, so no 2012/13 copy of a battle sprite survives on the server. |
| `_later/index.jsonl` | Same fields for those. Two lines added on 30 October 2026 (field `added`): `tasknpc/npc11.swf` (贝鲁特博士, uploaded 30 Nov 2017) and `peticon/peticon1.swf` (兔小子's icon, 5 Mar 2020), which the newbie quest needs and the first pass had missed. |
| `_site/aola.100bt.com/…`, `_site/index.jsonl` | Added 31 October 2026: files of the live server outside `/play/`, with paths from the host: the two 奥拉星 films the 百田大剧场 plays (`shipin/img/1343327424744_.flv`, 奥拉星2周年, uploaded 26 July 2012; `gwActivity/20121227/aola.flv`, the 战队 film, 16 May 2013). 42 MB. |
| `_wayback/…`, `_wayback/index.jsonl` | Added 31 October 2026: pictures of the January 2013 official site from the Wayback Machine (`url` is the raw capture, `…id_/…`): the 奥拉星官方专区 title, the 亚比 panel's background, 百田's games strip and the favicon, which the revival's page uses. |
| `_meta/live-cdn-inventory-2026-10-28.jsonl` | All 130,892 paths asked, with status, upload date, size and ETag: 71,073 exist on the server, 59,819 do not. |
| `_meta/live-versiondata-2026-09-11.swf`, `live-config-2026-10-22.xml`, `start.xml`, `play.html` | Today's live manifest, config and page, for comparison later. |
| `_meta/report-before-2014.md` | Files and sizes per folder. |

The four indexes (`index.jsonl`, `_later/`, `_site/`, `_wayback/`) are also
kept with the code in `tools/data/archive/`, so `tools/make_aola_archive.py`
can rebuild the archive from a checkout alone.

## Additions

The revival's curation tools took more files from the live server into
`game/` after the archive was made. Each has its CDN path, upload date and
SHA-1 in `game/FILES.jsonl`, and `tools/archive_additions.py` wrote a line
for each into the archive's indexes (field `added`: the date and the
reason). Files of 2010–2013 go to `index.jsonl`, later uploads to
`_later/index.jsonl`, the films to `_site/index.jsonl` and the Wayback
pictures to `_wayback/index.jsonl`.

| Run | Date | Files |
| --- | --- | --- |
| 1 | 31 Oct 2026 | the 2012 story quests' rooms, music, films and scripts (`tools/story_files.py`); shop book pages and the `plant/y000001–8` trees (`tools/add_later.py`); the theatre films (`tools/theatre.py`); 4 Wayback pictures. 247 lines in `index.jsonl` (48 MB), 332 in `_later` (49 MB) |
| 2 | 31 Oct 2026 | the 奥拉周刊 from issue 1 (`tools/weeklies.py`: 1,660 pages of 113 issues), the zoo animals' pictures, `zooitem/zooitem1–10`, the later zoo house `furniture/b020000`. 184 lines (77 MB) and 1,604 (168 MB) |
| 3 | 31 Oct 2026 | the 守护者's pictures `dailyactivity/dailyboss<race>` (27 files, 16 of 2011–12), `music/fightBgMusic1.mp3`. 16 and 12 lines |
| 4 | 31 Oct 2026 | the 保卫战 games' pictures (`pvzres/`, `guardnutres/`, `seadefendres/`), small pictures of 12 亚比, 舞动全星's songs, two entrance panels, `bumpbilliards/bumpbilliards` (2015), 时空隧道's pictures and panel, the 幻龙星系 quests' scripts and resources. 193 and 28 lines |
| 5 | 31 Oct 2026 | the 奥拉周刊 issues whole in one file (`weekly/aolaweekly1–20, 22.swf`), pictures of 2011–12 event bosses and 友人契约书's egg film, `petlearning/petlearning192` and `230`, the later 副本 choose panels, `fightassets/pet999`. 33 and 3 lines |
| 6 | 31 Oct 2026 | battle and 亚比蛋 pictures of 亚比 1–1426 the archive lacked, 斑比向前冲 (2017), 酷跑星世界 (2014–15), `bookfriendclub/seestory` (2011), `library_res/common_res_bubble`, an entrance panel. 1 and 67 lines |
| 7 | 1 Nov 2026 | 蓝羽灵者's picture and panel (10 January 2013), `stonebosspanel`, the planets' activities (`momekaevolution/*`, `activityres/yalunevolution*`, `bringupres/fishbringuppanel`, `rarepets/raredaheihei`), two 道馆 panels, `tasknpc/npc324` and `npc342`, `scene/aolatreefb` (2021). 7 and 7 lines |

The added files are not in the transfer pieces. `python
tools/extract_archive.py --out <archive folder> --from-cdn` downloads them
(and anything else missing) and keeps each only if its SHA-1 matches.

## How the files were found and dated

Nothing lists old files: the live manifest names only files changed since its
baseline (the original 2011 `scene/restaurant.swf` is in no list). Paths were
gathered from the captured manifests of 2012–2014, the 2013 and live
configs, Wayback Machine URLs, decompiled code, strings inside every SWF
(repeated over the newly saved files until a round found almost nothing new:
1,335, then 530, then 15 files), the 2013 material data (clothes, furniture,
items, cards, eggs by id) and numbered name patterns over the 2013 range.
A later pass added the clothes file names of `ClothesPartsDatas` (35 more
files from 2011: the scene skins of the following 亚比, such as
`skin/a000123.swf` for clothes 20123, which are not named after their id).

Each path was dated with a HEAD request. The CDN keeps the original upload
date: `skin/a000002.swf` shows 27 December 2011, the same day as the date Flash
wrote inside the file. Across the 16,158 saved SWFs that carry such a date,
none is later than its upload date beyond the one-day difference between China
time and UTC.

## Re-running

```bash
python tools/live_archive.py candidates …   # see the tool's help; sources as above
python tools/live_archive.py head --candidates candidates.txt --log head.jsonl
python tools/live_archive.py fetch --log head.jsonl --out archive --before 2014-01-01
python tools/live_archive.py report --log head.jsonl --index archive/index.jsonl
```

A later run that finds an ETag different from `index.jsonl` means the operator
replaced the file; the old copy here is then the only one. (Four large 2026
files, among them `pet/petfightnew.swf` and `map/map.swf`, changed between the
HEAD run and the download; their lines carry `replaced_since_head`. A retried
download appends a newer line, so read each index keeping the last line per path.)

To unpack the transfer pieces on another computer and check every file:

```bash
python tools/extract_archive.py --pieces <folder with archive-*.zip> --out <archive folder>
```

These are 百田's files, kept for preservation. Do not redistribute them.
