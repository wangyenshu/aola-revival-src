# Mods for the 沙盒

The 沙盒 (an addition of the revival; [GUIDE.md](GUIDE.md) shows how to use
it) runs **mods**: SWF files written in ActionScript 3 against a small API.
A mod can make rooms of its own, put characters in them who talk and give
choices, play animations, set up fights, define new 亚比 with their own
pictures, stats and skills, give 亚比 to the player, and remember the
player's progress.

This page covers:

- how mods are built (Apache Royale's compiler, from the command line or VS Code);
- the API, with every class, method and field;
- how a mod's 亚比 work;
- the examples;
- the 对手关卡 file format;
- how it all works inside the game.

> **Security.** A mod is a program. The game runs it with the game's own
> rights: it can do anything the game can. It can send any request to the
> server as the player (and so change the save), and through the Flash
> player's link to the page it can run JavaScript in the page, on the
> site's address. Only load mods whose source you have read or whose
> author you trust.

## A first mod

```as3
package
{
   import flash.display.Sprite;
   import mmo.revival.mod.IMod;
   import mmo.revival.mod.IModGame;
   import mmo.revival.mod.IModRoom;

   public class MyMod extends Sprite implements IMod
   {
      public function get info():Object
      {
         return {id: "mymod", name: "我的模组", author: "我", version: "1.0", description: "第一个模组"};
      }

      public function start(game:IModGame):void
      {
         game.room("first", {
            name: "第一个房间",
            background: Background,        // a class of the mod: a picture 560 high
            build: function(room:IModRoom):void
            {
               room.npc({name: "向导", look: 1, x: 500, y: 420, onClick: function():void
               {
                  game.talk({name: "向导"}, ["你好，#username#！", "这是我的模组。"]);
               }});
               room.door(860, 340, 100, 150, "离开", function():void { game.leave(); });
            }
         });
         game.enter("first");
      }
   }
}
```

The main class (the SWF's document class) extends `Sprite` and implements
`mmo.revival.mod.IMod`. When 开始 is pressed in the 沙盒, the game calls
`start` and passes an `IModGame`. The mod defines its rooms there and enters
the first one.

## Building

A mod is compiled against two libraries. Neither is put into the mod's SWF,
because the game supplies them when the mod runs:

- `playerglobal.swc`, Flash Player 10.1's classes;
- `aola-mod-api.swc`, the four interfaces of `mmo.revival.mod`.

A third, `aola-mod-embed.swc`, is linked into the mod: the classes the
compiler bases embedded files on (`mx.core.BitmapAsset`, `SoundAsset` and
the others; see [Pictures, animations and music](#pictures-animations-and-music)).
Only the ones a mod uses end up in its SWF.

The compiler is Apache Royale's, the same one that builds the rebuilt
modules of the game.

### With the repository

Requirements: Node.js 22.18 or newer, Java 11 or newer, and a checkout of
this repository. `npm run build:swf` downloads the compiler and
`playerglobal.swc` into `.toolchain/` the first time it runs.
`rebuild/build/setup-toolchain.sh` does only that step.

```bash
node tools/mod-sdk/build.mjs api                              # build/mod-sdk/aola-mod-api.swc and aola-mod-embed.swc
node tools/mod-sdk/build.mjs tools/mod-sdk/examples/hello     # tools/mod-sdk/examples/hello/bin/hello.swf
node tools/mod-sdk/build.mjs my-mod                           # a mod folder of your own
node tools/mod-sdk/build.mjs examples build/mods              # every example, with index.json
```

A mod folder holds an `asconfig.json` and its sources:

```
my-mod/
  asconfig.json
  src/
    MyMod.as
    art/...            more classes, pictures to embed
```

```json
{
	"config": "royale",
	"compilerOptions": {
		"targets": ["SWF"],
		"target-player": "10.1",
		"swf-version": 10,
		"source-path": ["src"],
		"external-library-path": ["../aola-revival/build/mod-sdk/aola-mod-api.swc"],
		"library-path": ["../aola-revival/build/mod-sdk/aola-mod-embed.swc"],
		"output": "bin/mymod.swf"
	},
	"mainClass": "MyMod"
}
```

`build.mjs` reads the following fields:

- `mainClass`;
- `compilerOptions.source-path`;
- `compilerOptions.library-path` (libraries to link in);
- `compilerOptions.output`.

It adds `playerglobal.swc`, the API SWC and the embed SWC itself. The other
fields are for VS Code.

### With VS Code

1. Install the extension **ActionScript & MXML** (by Bowler Hat). Its
   compiler driver, asconfigc, reads the same `asconfig.json`.
2. Get the Apache Royale SDK. Use the one in this repository's
   `.toolchain/royale/node_modules/@apache-royale/royale-js-swf/royale-asjs`,
   or install your own with `npm install @apache-royale/royale-js-swf`.
   In VS Code, run **ActionScript: Select Workspace SDK** and pick that
   `royale-asjs` folder.
3. Royale's configuration looks for `playerglobal.swc` under
   `$PLAYERGLOBAL_HOME/10.1/`. Set `PLAYERGLOBAL_HOME` to the repository's
   `.toolchain/playerglobal` before starting VS Code.
4. Build the two SWCs once (`node tools/mod-sdk/build.mjs api`), and point
   `external-library-path` at `aola-mod-api.swc` and `library-path` at
   `aola-mod-embed.swc`.
5. Build with **Terminal → Run Build Task → ActionScript: compile release**.
   The extension also completes code against the API's interfaces.

From a terminal, the same build is
`PLAYERGLOBAL_HOME=… npx asconfigc --sdk <royale-asjs> -p my-mod`.

### Pictures, animations and music

Pictures and animations can be drawn in code (with `Graphics`, as the
examples do) or embedded from files. An embedded file becomes a class of
the mod. Put the `[Embed]` on a class of its own, one file each; the path is
relative to that file:

```as3
package
{
   import mx.core.BitmapAsset;

   [Embed(source="../art/bg.png")]      // PNG, JPEG or GIF: a Bitmap
   public class Bg extends BitmapAsset
   {
   }
}
```

| File | The class extends | Gives |
| --- | --- | --- |
| a picture (`.png`, `.jpg`, `.gif`) | `mx.core.BitmapAsset` | a Bitmap |
| a symbol of a SWF made in Animate or another Flash tool (`source="art/art.swf", symbol="Hero"`) | `mx.core.MovieClipAsset` (a symbol with frames) or `mx.core.SpriteAsset` | a MovieClip or Sprite: the way to get timeline animations, such as a 亚比's battle sprite |
| an MP3 (11025, 22050 or 44100 Hz) | `mx.core.SoundAsset` | a Sound |
| any other file (`mimeType="application/octet-stream"`) | `mx.core.ByteArrayAsset` | its bytes |

An `[Embed]` on a variable (`[Embed(source="bg.png")] public static const
Bg:Class;`) works too, but with this compiler it puts the file into the SWF
twice.

Music: give a room's `music` (or `IModGame.music`) the class of an embedded
MP3, or a Sound. It plays looped while the room is shown, stops during
fights and when the player switches the music off, and the scene's own
music comes back outside the 沙盒. The `story` example plays its own tune
(`src/Tune.as`, `art/tune.mp3`, made by `art/make_tune.py`) on the shore and
a music file of the game in the lighthouse room.

Classes written outside the package block (as in the examples) are defined
in the order of the file. A static constant initialised with one of them
(`static const Bg:Class = Garden;`) is null if that class comes later in the
file; use the class itself where it is needed instead.

A mod is at most 16 MB. It cannot use the game's own art files (百田's), and
should not try to: those are 百田's.

## Loading a mod

In the game, open **沙盒 → 模组**:

- **导入模组** loads a `.swf` file from your computer.
- **载入** loads one of the examples the site comes with, and **移除** to its
  right removes it again. The examples are built by `npm run build:swf` into
  `revival/mods/` beside the game files, and listed in
  `revival/mods/index.json`.

The mods loaded are listed at the top, each with **开始** (start it) and
**移除** (forget it: its SWF is unloaded and stopped, its pending replies and
conversations dropped, and its room left if the player is in it).

Up to 8 mods can be loaded at once. Each keeps its own rooms, saved data and
music; the rooms of one are shown at a time, and starting another mod moves
to its rooms. Two mods conflict when they use the same 亚比 number:

- A mod that lists its 亚比 numbers in `info.yabi` is refused when it is
  loaded if a mod already loaded uses one of them (the panel names that
  mod).
- Otherwise the second mod's `species` for that number is refused
  (`done(false)`), and its 亚比 is missing.

A mod with the `id` of one loaded replaces it: to load a new build of a mod,
import it again.

## The API

All four interfaces are in the package `mmo.revival.mod` (sources:
`rebuild/src/shared/mmo/revival/mod/`).

Rooms are 560 high and 960 to 2880 wide. Positions are room coordinates:
0, 0 is the top left of the room, and characters stand on their feet. Rooms
wider than 960 scroll as the wide rooms of the game do. The text of a
conversation (`talk`) may use the HTML the game's panels use
(`<font color='#FF6600'>…</font>`) and `#username#` (the player's name).
Other text (names, door labels, `say`, room names) is shown as it is.

### `IMod`

The interface the mod's main class implements.

| Member | |
| --- | --- |
| `get info():Object` | `{id, name, author, version, description, yabi}`. `id` (letters, digits, `_`, `-`; 1–32) is the key of the mod's saved data: keep it the same in every version. `name` is shown in the panel and at the top of its rooms. `yabi` (optional): the 亚比 numbers the mod defines, so that a conflicting mod is found when it is loaded |
| `start(game:IModGame):void` | called each time 开始 is pressed: define rooms and 亚比, then `game.enter(...)` |

### `IModGame`

The game, as `start` receives it. `game.currentRoom` returns the room that is
shown.

**Rooms**

| Member | |
| --- | --- |
| `room(id, def)` | define a room (fields below) |
| `enter(roomId, spawn = null)` | show the room, the player at the spawn point (default `"start"`). Called while a scene is loading, it waits until that scene is shown |
| `leave()` | leave the mod: back to where the 沙盒 was started (from a home or a 副本: to the last place outdoors) |
| `get currentRoom():IModRoom` | the room shown, or null |

The fields of a room's `def`:

| Field | |
| --- | --- |
| `name` | shown at the top left with the mod's name |
| `background` | a DisplayObject, a BitmapData or a Class. It is scaled to 560 high, and its width then (kept to 960–2880) is the room's width |
| `width` | the room's width when there is no background (960–2880, default 960; the room is then dark blue) |
| `walk` | where the player may walk. `function(x, y):Boolean` returning true for a wall; or a picture (BitmapData, DisplayObject or Class) stretched over the room: black is wall, white or transparent is floor. Default: everywhere |
| `music` | the room's music: the class of an embedded MP3, or a Sound (the mod's own music); or a music file of the game, such as `"music/themeparknew4.mp3"` |
| `spawns` | entry points: `{name: [x, y], …}`. `"start"` is used when `enter` names none. A name the room does not have, or no spawns, puts the player at 480, 470 |
| `build` | `function(room:IModRoom):void`, called each time the room is shown, to put its characters, opponents, doors and pictures. A room is built anew every time it is entered: keep what must last with `setData` |

**Conversations, films and messages**

| Member | |
| --- | --- |
| `talk(speaker, pages, done = null)` | a conversation in the game's NPC panel. `speaker`: `{name, picture}` (picture: DisplayObject or Class, drawn at the left; optional; a DisplayObject already shown in the room is drawn as a copy). `pages`: each a String, or `{text, choices: [[label, function], …]}`. The pages are shown one after another, and a click goes on. A choice closes the panel and calls its function, so put choices on the last page. `done()` is called after the last page (not after a choice, nor when the panel is closed with ×) |
| `film(clip, done = null, seconds = 0)` | show a DisplayObject over the whole screen (960 × 560), the room dimmed under it, with a 跳过 button; then `done()`. A MovieClip of several frames plays from its first frame to its last; a whole embedded SWF (`MovieClipLoaderAsset`) plays its own timeline once loaded. Anything else stays until it dispatches `Event.COMPLETE`, or for `seconds` |
| `message(text)` | a message box |
| `music(music)` | change the music of the room shown: the class of an embedded MP3 or a Sound, a music file of the game, or `""` for none (API 2; API 1 took only a music file of the game). Called before the room is shown, it takes effect when it is |

**Fights and 亚比**

| Member | |
| --- | --- |
| `fight(team, done = null, heal = true)` | fight 1–10 opponents one after another. Each is `{race, level, hp, at, de, sa, sd, sp}`: `race` is a 亚比 of the game or of the mod, `level` is 1–999, and the six are 体力, 攻击, 防御, 特攻, 特防 and 速度 in percent of the normal value (1–10000, default 100). `done(win:Boolean)` (a team the server refuses counts as a loss). `heal`: the bag's 亚比 get their 体力 and PP back before each fight. A win brings nothing (no experience). More than 10 opponents: the first 10. While a fight is on, another `fight` is ignored (no `done`) |
| `species(def, done = null)` | define a 亚比 of the mod (next section). `done(ok:Boolean)` |
| `givePet(race, level = 1, done = null)` | give the player a 亚比: a 亚比 of the game, or one this mod has defined. `level`: 1–100. It goes to the bag, or to the 仓库 when the bag is full. `done(ok:Boolean)` |

**Saved data and the rest**

| Member | |
| --- | --- |
| `getData(key):*` | a value the mod saved, or undefined |
| `setData(key, value)` | save a value (JSON-like: numbers, strings, booleans, arrays, plain objects; `undefined` deletes it). The data is kept with the player's game, read before `start` and sent half a second after a change (with the changes made meanwhile). At most 64 KB (UTF-8) per mod and 1 MB for all mods; data over that is not kept (the console says so) |
| `after(seconds, f)` | call `f()` after `seconds`, unless the room has been left by then. Asked for before a room is shown (in `start`, a door's handler), the time counts from when it is |
| `log(...parts)` | write to the browser's console |
| `get playerName():String` | the player's name as the game shows it (as `#username#`) |
| `get apiVersion():int` | 2 |

### `IModRoom`

The room that is shown. The room's `build` function receives it, and
`game.currentRoom` returns it.

| Member | |
| --- | --- |
| `get id():String`, `get roomWidth():int` | |
| `add(d, x = 0, y = 0, layer = "back"):DisplayObject` | put a picture in the room. `layer`: `"back"` (behind the players), `"players"` (among them), `"front"` (over them), `"screen"` (fixed on the screen as the room scrolls) |
| `remove(d)` | take it away |
| `door(x, y, w, h, label, onEnter, drawn = true):Sprite` | a door, the rectangle x, y, w, h. A click walks the player there, then calls `onEnter()` (for example `game.enter("room2", "fromRoom1")`). `label` is written on it; `drawn` draws a light frame round it |
| `npc(def):IModNpc` | a character (fields below) |
| `foe(def):IModNpc` | an opponent: a character with `team` (as `fight`), `heal` (default true), `boss` (drawn half again as large), and `onWin`, `onLose` (functions). A click walks the player up to it and starts the fight; beaten, it goes away |
| `say(d, text, seconds = 3)` | a speech bubble over any DisplayObject of the room |
| `get player():Point` | where the player stands |
| `walkTo(x, y, then = null)` | walk the player there; `then()` on arrival |
| `onLeave(f)` | `f()` when the room is left |

The fields of a character (`npc`, `foe`):

| Field | |
| --- | --- |
| `name` | shown under it (an opponent also shows its team's size and first level) |
| `look` | a DisplayObject, a Class, or a race: a 亚比 of the mod (its `walk` picture, or its icon, made at most 110 high) or of the game (dressed as that 亚比, as the wild 亚比 are). Default: 兔小子 (race 1) |
| `picture` | its picture in `talk()`. Default: the look's class, the mod 亚比's icon, or a snapshot of the look |
| `x`, `y` | where it stands (its feet) |
| `scale` | default 1 |
| `tip` | the text shown when the mouse is over it (default: none; an opponent: 点击挑战) |
| `onClick` | `function():void`, called once the player has walked up to it |

### `IModNpc`

| Member | |
| --- | --- |
| `get view():DisplayObject` | its look |
| `get npcName():String` | its name |
| `say(text, seconds = 3)` | a speech bubble over it |
| `talk(pages, done = null)` | `game.talk` with its name and picture |
| `moveTo(x, y, seconds = 1, then = null)` | glide there |
| `remove()` | take it away |

## A mod's 亚比

```as3
game.species({
   id: 900777,                         // 900001–999999: pick a number of your own
   name: "泡泡蛙",
   attr: 10,                           // or [10, 11]; the game's attribute numbers (9 火, 10 水, 11 草 …)
   stats: [70, 60, 65, 80, 70, 75],    // 体力, 攻击, 防御, 特攻, 特防, 速度 base values, 1–255
   skills: [[0, 1014], [4, 11014], [8, 1148]],   // [level learnt, skill id of the game]
   exp: "2",                           // experience curve of the game (default, and for an unknown one, "2")
   icon: Frog,                         // Class: its picture, about 150 high, feet at 0, 0
   fight: FrogFight,                   // optional Class: battle sprite facing the viewer
   back: FrogBack,                     // optional Class: battle sprite seen from behind
   walk: FrogWalk                      // optional Class: its figure in rooms
}, function(ok:Boolean):void { /* the game knows it */ });
```

**The battle sprite.** The battle sprite follows the contract of the game's
own (`fightassets/pet<race>`). It is a MovieClip of at least five frames:

- frame 1: standing;
- frame 2: hurt;
- frame 3: special attack;
- frame 4: physical attack;
- frame 5: status skill.

In frames 2–5 a child named `mc` plays the move. Its frame labels drive the
rest: `eff` is where the skill's effect starts, and `move` with `p1`–`p4`
makes it step towards the other side and back. A sprite of fewer frames,
or none, is shown standing (the icon stands in) and hops when it attacks.
When `back` is missing, the `fight` sprite is mirrored for the player's
side.

**Where its pictures are used.** The icon (or the battle sprites) shows in
battles, the 亚比 bag, the 仓库, the following 亚比 and the panels that ask
for 亚比 pictures. In rooms the `walk` figure is used, or the icon, scaled
to about 110 high.

**Skills.** A mod's 亚比 has the game's skills: their effects and
animations are the game's. Its stats grow with the game's formulas and its
天赋 (individual values) are random, as for any 亚比. A mod's 亚比 cannot
be caught with 亚比球 and does not evolve.

**What the player keeps.** The game knows a mod's 亚比 only while the page
runs and once its mod has called `species`. A player who has one (from
`givePet`) keeps it in the save. At login, 亚比 the game does not know are
put aside, and they come back to the bag or the 仓库 when their mod is
started and calls `species` again. Each keeps the id of the mod that made
it: another mod using the same number gets none of them back, and while
one mod's 亚比 is known in a run, another mod cannot define or give that
number (`done(false)`). Keep the `id` and the definition the same across
versions of a mod, and pick a number other mods are unlikely to use.

**Errors.** The server refuses a definition that cannot be (`done(false)`;
the log says why):

- an id outside 900001–999999, or one another mod has defined in this run;
- no name (a longer one is cut to 12 characters);
- a first attribute that is not the game's (a second one that is not
  becomes the first);
- stats outside 1–255;
- no skill, or a skill that is not the game's (at most 40 are kept).

The server answers with the definition as it keeps it, and the game's
panels get that one.

## Examples

`tools/mod-sdk/examples/` holds three examples. The site serves them as
`revival/mods/*.swf`, and the 模组 page lists them. Each example's
`about.json` holds its name and description for that page.

| Folder | Shows |
| --- | --- |
| `hello` | one room drawn in code, a walk function, a character with a question, a door out, saved data (visits) |
| `story` | two rooms joined by doors (a wide room of 1400), conversations with choices, a film drawn in code (ended with `Event.COMPLETE`), an opponent with a team of the game's 亚比, progress kept with `setData`, a 亚比 given as a reward, music of its own (an embedded MP3) and of the game |
| `yabi` | a 亚比 of the mod (`species`) standing in the room, fought, and given to the player |

## The 对手关卡 file

The 沙盒's first page (对手关卡) sets up a list of opponents fought one after
another. It saves and reads the list as a JSON file:

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

| Field | |
| --- | --- |
| `name` | up to 30 characters |
| `heal` | default true: the bag's 亚比 get their 体力 and PP back before each fight |
| `enemies` | 1 to 10 opponents. `race`: a 亚比 that can fight. `level`: 1–999 (above 100 the stats keep growing by the same formulas). `hp` … `sp`: 1–10000, percent of the normal value (default 100) |

Mods fight the same way: `IModGame.fight` sends such a list. The server
(`server/src/game/sfs2013/sandbox.ts`, `SundriesExtension.revival_sandbox`)
checks every value.

## Inside the game

The runtime has the following parts:

- **Loading.** `mmo.control.ModRun` (the control module, `rebuild/src/control/`)
  loads a mod's SWF with `Loader.loadBytes`. Only files that start with a
  SWF signature (FWS, CWS or ZWS) are loaded. The SWF goes into an
  application domain of its own, under the game's: the mod sees the game's
  classes, and the game sees the mod only through `IMod`. A newer build of a
  mod therefore replaces the old one without a reload, and several mods'
  classes do not mix. `ModRun` keeps the mods loaded and which one's room is
  shown; each mod has a `ModGame`, which implements `IModGame`.
- **Rooms.** They are shown by the 沙盒 room, `scene/sandboxroom`
  (`rebuild/src/scenes/sandboxroom`, `SandboxRoom` implements `IModRoom`;
  characters are `ModPerson`). When built, the room asks `ModRun` for the
  room to show and its mod. When shown, it hands itself to the room's
  `build` function.
  Each player is in a server room of their own (`sandboxroom_<user>`).
- **Conversations.** They use the rebuilt NPC panel
  (`task/tasknpc`, `NpcTalkPanel.showAs`). Its choices come back as task
  actions `revival_mod:<n>:<i>`.
- **Fights.** They go through `SandboxRun` and the server's
  `revival_sandbox`.
- **A mod's 亚比.**
  - Pictures: given to the game's modules under the names they look up
    (`mmo.pet.peticon<race>_L`/`_S`, `mmo.petfight.pet<race>_1`/`_2`,
    through `mmo.revival.RDef`), and to the era panels through the rebuilt
    `pet/peticon` (`ModPetIcon`).
  - Numbers: added to the emulator's tables
    (`server/src/game/sfs2013/mods.ts`) and, for the panels that read them
    in the game, to the rebuilt PMService (`pet/pmservice`, `addPM`).
- **Saved data and gifts.** They go through `SundriesExtension.revival_mod`
  (`mods.ts`). The data is kept in the player's record, under `modData`.
