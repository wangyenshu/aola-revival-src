# 沙盒: custom 关卡

The 沙盒 is the revival's own (it was not in the 2013 game). Its button sits on the control bar under the 工具箱. In it a player sets up a 关卡 and fights it. The 关卡 can be exported to a file and imported again, to keep it or to share it.

## What a 关卡 is now (format version 1)

A 关卡 is up to 10 opponents fought one after another. Each one has:

- `race`: any 亚比 that can fight, by its 图鉴 number.
- `level`: 1–999. Above 100 the stats keep growing by the 2013 formulas.
- `hp`, `at`, `de`, `sa`, `sd`, `sp`: its 体力, 攻击, 防御, 特攻, 特防 and 速度, each in percent of what it has at that level. 100 means as it is. The range is 1–10000 (one hundredth to a hundred times).

`heal` (default true) gives the bag's 亚比 their 体力 and PP back before each fight.

Winning a 沙盒 fight brings nothing: no experience, no effort points, no evolution, no catching. That way the 沙盒 cannot be used to level 亚比 past the game. The server checks every value and refuses a file it cannot read, with a message (`server/src/game/sfs2013/sandbox.ts`, command `SundriesExtension.revival_sandbox`).

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

A missing stat counts as 100. The JSON Schema is `docs/sandbox-level.schema.json`. Tools that write 关卡 should check their output against it.

## Custom maps (planned: format version 2)

The aim is a 关卡 that is a small 副本 of the player's own: rooms with their own pictures, a walkable area, doors from room to room, and opponents standing in the rooms (a boss in the last).

### What was weighed

**Scene SWFs made in a Flash tool.** This means Apache Royale or Apache Flex (`mxmlc` with `[Embed]`ed pictures), Haxe/OpenFL (which can still write SWF), or JPEXS FFDec to swap the pictures in a template scene. It would give animated rooms in the game's own scene format (the `background` / `obstruction` / `foreground` layers of `SceneBase`).

Against it:

- **Unsafe to share.** A SWF carries code, and the game runs what it loads. A shared room could call the page's JavaScript through `ExternalInterface`, read or wipe the browser's saves (IndexedDB), or send the player elsewhere. The game cannot strip the code at load time without a SWF rewriter of its own. Flash Player 10.1's `ByteArray` cannot even unpack LZMA SWFs.
- **Hard to author.** Royale and Flex are frameworks for code, not drawing tools: a level maker would need a Java toolchain and a build script. No open-source tool draws vector timeline art the way Flash Professional did. FFDec can replace pictures in a template but is awkward for anything more.

**A data file with pictures (recommended).** Each room is:

- a background picture (PNG or JPG, 960×560, or wider for a room that scrolls like 服装店);
- a walk mask: a second picture, or a small grid, where transparent or white is floor and the rest is blocked;
- points and rectangles for the start, the doors and the opponents.

Everything goes in the same JSON file as version 1, the pictures as base64. The game loads the pictures with `Loader.loadBytes`, which Flash Player 10.1 and Ruffle both have. Nothing in the file can run, so sharing it is as safe as sharing a picture. Pictures can be drawn in any program (GIMP, Krita, Photoshop, or a screenshot of an existing room). One file holds the whole 关卡.

### Proposed shape of version 2

```json
{
  "format": "aola-revival-level",
  "version": 2,
  "name": "…",
  "heal": true,
  "rooms": [
    {
      "id": "r1",
      "background": "data:image/jpeg;base64,…",
      "mask": "data:image/png;base64,…",
      "size": [960, 560],
      "start": [480, 470],
      "music": "music/fbaixi.mp3",
      "doors": [{ "rect": [880, 300, 80, 160], "to": "r2", "open": "cleared" }],
      "enemies": [{ "at": [600, 380], "race": 43, "level": 60 }]
    }
  ]
}
```

- `enemies` keeps its version-1 meaning: a 关卡 without `rooms` is the fight list it is now.
- `open: "cleared"` opens a door only when its room's opponents are beaten.
- A `background` may instead name a room of the game (`"scene": "fbaixi1"`). Its pictures are then taken without its code: the revival's own scene builds already split a scene's art from its code (`tools/swf_transplant.py --drop-art-abc`). That gives the 四大副本's rooms as backdrops with no new drawing.

**In the game:** one rebuilt scene, a "沙盒 room", shows the current room's picture, walks on the mask (its `isBlocked` reads the mask's pixels), stands the opponents as their 亚比 (as the 守护者 whose pictures are lost already stand) and opens the doors. It runs in a room of its own on the server, without other players.

### The editor

The editor makes the file, and does not need to be part of the game. The plan is a single static web page with no build step, kept in its own folder (`tools/level-editor/`) or its own repository:

- load pictures;
- paint the walk mask with a brush and an eraser;
- drag the start, the doors and the opponents into place;
- set the opponents (number, level, the six stats);
- export the JSON, and import one to edit it.

Anyone may write another editor against `docs/sandbox-level.schema.json`. The game reads only the file.
