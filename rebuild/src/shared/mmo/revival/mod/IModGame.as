package mmo.revival.mod
{
   import flash.display.DisplayObject;

   /**
    * The game, as a mod sees it (docs/MODDING.md has the whole reference).
    * Positions are in room coordinates: 0, 0 is the top left of the room, the
    * room is 560 high and 960 to 2880 wide; players stand on their feet.
    */
   public interface IModGame
   {
      /** The API version (2: music() and a room's music take a mod's own Sound). */
      function get apiVersion():int;

      /** The player's name. */
      function get playerName():String;

      /**
       * Define room id. def:
       *   name        shown at the top left
       *   background  DisplayObject, BitmapData or Class (scaled to 560 high; its width
       *               then, 960 to 2880, is the room's)
       *   width       the room's width when there is no background (default 960)
       *   walk        where one may walk: BitmapData or DisplayObject (black = wall,
       *               white or clear = floor; stretched over the room) or
       *               function(x, y):Boolean (true = wall); default everywhere
       *   music       the room's music: a Sound or a class of one (an MP3 the mod
       *               embeds), or a music file of the game ("music/xxx.mp3")
       *   spawns      {name: [x, y]}; "start" is used when enter() names none
       *   build       function(room:IModRoom):void, called each time the room is
       *               shown: put its NPCs, opponents, doors and pictures there
       */
      function room(id:String, def:Object):void;

      /** Show room id, the player at spawn (default "start"). */
      function enter(roomId:String, spawn:String = null):void;

      /** Leave the mod: back to where the 沙盒 was opened. */
      function leave():void;

      /** The room shown, or null. */
      function get currentRoom():IModRoom;

      /**
       * A conversation in the game's NPC panel. speaker: {name, picture
       * (DisplayObject or Class, drawn at the left; optional)}. pages: each a
       * String, or {text, choices: [[label, function():void], …]}; the pages are
       * shown one after another, a page with choices ends with the choice made.
       * done() after the last page (not after a choice). Text may use
       * <font color='#FF6600'>…</font> and #username# (the player's name).
       */
      function talk(speaker:Object, pages:Array, done:Function = null):void;

      /**
       * Show clip over the whole screen (960 × 560), the room dimmed under it, with a 跳过
       * button; then done(). A MovieClip of several frames plays from its first frame to its
       * last; anything else stays until it dispatches Event.COMPLETE, or for seconds when
       * seconds is given.
       */
      function film(clip:DisplayObject, done:Function = null, seconds:Number = 0):void;

      /**
       * Fight a team (1 to 10 opponents, one after another): each {race, level,
       * hp, at, de, sa, sd, sp} (the six are percentages of its stats, default 100).
       * done(win:Boolean). heal: the bag's 亚比 are healed before each fight.
       */
      function fight(team:Array, done:Function = null, heal:Boolean = true):void;

      /**
       * Define a 亚比 of the mod. def:
       *   id        900001 to 999999
       *   name      its name
       *   attr      its attribute, or [attr, attr]  (attribute numbers of the game)
       *   stats     [hp, attack, defence, sp. attack, sp. defence, speed] (1 to 255)
       *   skills    [[level, skill id], …] (skills of the game) learnt as it grows
       *   exp       experience curve ("1" to "6", default "2")
       *   icon      Class of its picture (Sprite or MovieClip, drawn about 150 high,
       *             its feet at 0, 0)
       *   fight     Class of its battle sprite facing the viewer (MovieClip: frame 1
       *             stands, 2 hurt, 3 special attack, 4 physical attack, 5 status skill),
       *             optional (the icon stands in)
       *   back      Class of its battle sprite seen from behind (when it is the
       *             player's); optional (fight, mirrored, stands in)
       *   walk      Class of its figure in rooms; optional (the icon, smaller)
       * done(ok:Boolean) once the game knows it.
       */
      function species(def:Object, done:Function = null):void;

      /** Give the player a 亚比 (any of the game, or one of the mod's): done(ok:Boolean). */
      function givePet(race:int, level:int = 1, done:Function = null):void;

      /** A value the mod saved (JSON: numbers, strings, booleans, arrays, objects), or undefined. */
      function getData(key:String):*;

      /** Save a value for the mod (kept with the player's game; at most 64 KB in all). */
      function setData(key:String, value:*):void;

      /** A message box. */
      function message(text:String):void;

      /**
       * Change the music of the room shown: a Sound or a class of one (an MP3 the
       * mod embeds, played looped), a music file of the game ("music/xxx.mp3"),
       * or "" for none. (API 2; in API 1 only a music file of the game.)
       */
      function music(music:*):void;

      /** f() after seconds, unless the room has been left by then. */
      function after(seconds:Number, f:Function):void;

      /** Write to the log (the browser's console). */
      function log(... parts):void;
   }
}
