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
| `_meta/live-cdn-inventory-2026-10-28.jsonl` | All 130,892 paths asked, with status, upload date, size and ETag: 71,073 exist on the server, 59,819 do not. |
| `_meta/live-versiondata-2026-09-11.swf`, `live-config-2026-10-22.xml`, `start.xml`, `play.html` | Today's live manifest, config and page, for comparison later. |
| `_meta/report-before-2014.md` | Files and sizes per folder. |

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

These are 百田's files, kept for private preservation. Do not redistribute.
