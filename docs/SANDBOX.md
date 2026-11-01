# 沙盒 关卡 files

The 沙盒 (an addition of the revival; see [GUIDE.md](GUIDE.md) for how to
use it) reads and writes 关卡 as JSON files. There are two formats:

- **Version 1**: a list of up to 10 opponents, fought one after another.
- **Version 2**: a pack of pictures and 关卡 made of rooms joined by doors,
  with opponents standing in the rooms.

Both have `"format": "aola-revival-level"`. The JSON Schema of both is
`docs/sandbox-level.schema.json`; tools that write 关卡 files should check
their output against it.

## Opponents

Both formats describe an opponent the same way:

| Field | Values | Meaning |
| --- | --- | --- |
| `race` | a 图鉴 number | the 亚比; it must be one that can fight |
| `level` | 1–999 (default 1) | above 100 the stats keep growing by the same formulas |
| `hp`, `at`, `de`, `sa`, `sd`, `sp` | 1–10000 (default 100) | 体力, 攻击, 防御, 特攻, 特防, 速度 in percent of the normal value at that level |

Winning a 沙盒 fight brings nothing: no experience, effort points,
evolution or catching. The server
(`server/src/game/sfs2013/sandbox.ts`, command
`SundriesExtension.revival_sandbox`) checks every value and refuses a file
it cannot read, with a message.

## Version 1

```json
{
  "format": "aola-revival-level",
  "version": 1,
  "name": "我的关卡",
  "heal": true,
  "enemies": [
    { "race": 43, "level": 150, "hp": 300, "at": 100, "de": 100, "sa": 100, "sd": 100, "sp": 100 },
    { "race": 605, "level": 999 }
  ]
}
```

| Field | Meaning |
| --- | --- |
| `name` | up to 30 characters |
| `heal` | default true: the bag's 亚比 get their 体力 and PP back before each fight |
| `enemies` | 1 to 10 opponents |

A file with `enemies` and no `levels` is read as version 1.

## Version 2: 关卡 packs

```json
{
  "format": "aola-revival-level",
  "version": 2,
  "name": "我的关卡包",
  "author": "",
  "images": {
    "bg1": "data:image/jpeg;base64,…",
    "mask1": "data:image/png;base64,…",
    "fg1": "data:image/png;base64,…",
    "tree": "data:image/png;base64,…"
  },
  "levels": [
    {
      "id": "l1",
      "name": "第一关",
      "heal": true,
      "start": "r1",
      "next": "l2",
      "rooms": [
        {
          "id": "r1",
          "name": "入口",
          "background": "bg1",
          "mask": "mask1",
          "overlay": "fg1",
          "music": "music/aixifb.mp3",
          "props": [{ "image": "tree", "at": [300, 200], "front": false }],
          "spawns": { "start": [480, 470], "fromr2": [880, 400] },
          "doors": [
            { "rect": [900, 300, 60, 160], "to": "r2", "spawn": "start", "open": "always", "label": "下一个房间" },
            { "rect": [0, 300, 60, 160], "to": "l2/r1", "open": "cleared" },
            { "rect": [440, 0, 80, 60], "to": "#finish", "open": "cleared", "label": "通关" }
          ],
          "enemies": [
            {
              "id": "e1", "at": [600, 380], "name": "守卫", "boss": false,
              "team": [{ "race": 43, "level": 60 }]
            }
          ]
        }
      ]
    }
  ]
}
```

### Pack

| Field | Meaning |
| --- | --- |
| `name`, `author` | up to 30 characters each |
| `images` | pictures by id: PNG or JPG as `data:` URLs, each at most 2880 × 560 |
| `levels` | 1 to 20 关卡 |

Ids (of pictures, 关卡, rooms, entry points and opponents) are 1 to 32
letters, digits, `_` or `-`.

### 关卡

| Field | Meaning |
| --- | --- |
| `id`, `name` | |
| `heal` | default true: heal the bag before each fight |
| `start` | the room the 关卡 starts in |
| `next` | the 关卡 started after this one is finished (optional) |
| `rooms` | 1 to 20 rooms |

### Room

| Field | Meaning |
| --- | --- |
| `id`, `name` | |
| `background` | required picture id. It sets the room's size: 560 high and 960 to 2880 wide (wider than 960 scrolls). A picture of another height is scaled to 560 high; if it is then narrower than 960 it is stretched to 960, if wider than 2880 squeezed to 2880. |
| `mask` | optional picture id: where the player can walk, stretched over the room. A pixel with alpha under 128 is floor; an opaque pixel is wall if dark (luminance under 128) and floor if light. Without a mask the whole room is floor. |
| `overlay` | optional picture id drawn over the players at 0, 0, scaled like the background |
| `props` | up to 32 pictures `{image, at: [x, y], front}` placed by their top-left corner, behind the players or in front of them (`front: true`) |
| `music` | a music file of the game, `music/<name>.mp3` (optional) |
| `spawns` | up to 16 named entry points `[x, y]`; `start` is used when a door names none |
| `doors` | up to 16 doors |
| `enemies` | up to 12 opponents standing in the room |

One picture may be used by several rooms.

### Door

| Field | Meaning |
| --- | --- |
| `rect` | `[x, y, width, height]` in room coordinates. A click walks the player there and goes through. |
| `to` | `"r2"`: a room of the same 关卡; `"l2/r1"`: a room of another 关卡; `"#finish"`: the 关卡 is finished; `"#exit"`: leave the 沙盒 |
| `spawn` | the entry point in the target room (default `start`) |
| `open` | `"always"` (default) or `"cleared"`: only once every opponent of the room is beaten |
| `label` | text drawn on the door |

### Opponent in a room

| Field | Meaning |
| --- | --- |
| `id` | unique in its room; a beaten opponent stays beaten for the rest of the run |
| `at` | `[x, y]`, where it stands (its feet) |
| `name` | shown under it with its level |
| `boss` | default false; true draws it larger |
| `team` | 1 to 10 opponents fought one after another (fields as above) |

The opponent is drawn as the first 亚比 of its team.

### Limits

A pack file is at most 16 MB. It holds at most 64 pictures, 20 关卡, 20 rooms
a 关卡, and per room 16 doors, 12 opponents, 32 props and 16 entry points.

## In the game

The rooms of a pack are shown by the 沙盒 room, `scene/sandboxroom`
(`rebuild/src/scenes/sandboxroom`). `mmo.control.SandboxRun` in the control
module keeps the run: the decoded pictures, the current 关卡 and room, the
opponents beaten. Pictures are decoded once with `Loader.loadBytes`. Each
player is in a server room of their own (`sandboxroom_<user>`). The fights
are the version-1 fights. A room's `music` plays while it is shown and
after its fights.

## The editor

`tools/level-editor/` is a static web page (HTML, CSS and JavaScript, no
build step, nothing loaded from other sites). The site's build copies it to
`editor/` beside the game; it also works opened from the folder. Beside the
game it reads the 亚比 names from the game's `revival/pets.json`. It keeps the
pack being edited in the browser's localStorage.

`tools/level-editor/pack.js` holds the format's rules: checking a pack and
turning a version-1 file into a one-room 关卡. It also runs under Node and is
tested by `server/test/levelpack.test.ts`. `docs/examples/
sandbox-pack-example.json` is a pack of two 关卡.

Other editors can be written against the schema; the game reads only the
file.

## Design notes

Two ways of making custom maps were considered.

**Scene SWFs made with a Flash tool** (Apache Royale or Flex with embedded
pictures, Haxe/OpenFL, or FFDec replacing the pictures of a template scene)
would give rooms in the game's own scene format. They were rejected because
a SWF carries code that the game would run: a shared room could call the
page's JavaScript, read or delete the browser's saves, or send the player
elsewhere, and the game cannot strip the code when loading it. They are also
hard to make without Flash Professional.

**A data file with pictures** was chosen. Pictures can be drawn in any
program, the whole 关卡 is one file, nothing in it can run, and Flash
Player 10.1 and Ruffle can both decode PNG and JPG with `Loader.loadBytes`.
