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
      /** The API version (2: music() and a room's music take a mod's own Sound; 3: 组队; 4: rooms on the game's scenes, party, items, playerLook). */
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
       *   scene       (API 4) a scene of the game ("fbsiwude1"): the room is drawn with
       *               its art and walked as it is (background, walk and width unused);
       *               IModRoom.part finds its pieces by name
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
       * together: one battle against the whole team (as a trainer sends out one
       * 亚比 after another: the next comes out when the one before falls);
       * otherwise one battle for each.
       */
      function fight(team:Array, done:Function = null, heal:Boolean = true, together:Boolean = false):void;

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

      // 组队 (API 3; a shared server). In a team, a room of the mod is one room for the whole
      // team (members who run the same mod, of the same version), and the leader going into one
      // takes the members along.

      /** The team's members, the leader first; [] when one plays alone. */
      function get team():Array;

      /** The team's leader, or "" alone. */
      function get teamLeader():String;

      /** This player leads the team (or plays alone). */
      function get isLeader():Boolean;

      /** The other players in the room shown. */
      function get playersHere():Array;

      /** Tell the team's other members running this mod: their onTeam(event) get (name, data). data: JSON-like, 4 KB. */
      function sendTeam(event:String, data:* = null):void;

      /** f(from:String, data:*) when another member sends event. */
      function onTeam(event:String, f:Function):void;

      // API 4.

      /**
       * The mod's own 亚比 and 道具 instead of the player's, until the mod's rooms are left (or
       * endParty). def:
       *   pets      [{race, level, keep, follow}, …] (1 to 12; the first six in the bag)
       *             keep: this one must stay in the bag, and its fall ends a fight as lost
       *             follow: this one follows the player
       *   items     {道具 id: count} (type 2 of the game: 61 高级体力糖, 104 高级活力豆 …)
       *   noHeal    words: healing all (the bag's 恢复, the HELLO's 亚比治疗) is refused with
       *             them, and fights heal nobody
       *   keepText  the battle's words when the one to keep falls
       *   fresh     a new party, though the mod's from the last time is kept
       *   vip       the player is a 蓝宝石 while the party is out (the HELLO's 远程亚比仓库
       *             for the party's 亚比 beyond the bag's six …)
       * The party is kept for the mod when it ends and comes back as it was the next time
       * (unless fresh). done(state) as partyState gives it, or done(null) if refused.
       */
      function party(def:Object, done:Function = null):void;

      /** The player's own 亚比 and 道具 back (the party kept for the mod). done(). */
      function endParty(done:Function = null):void;

      /**
       * done({party, pets: [{id, race, level, hp, maxHp, bag, keep}], items: {id: count}}):
       * the 亚比 and 道具 as they are now (the party's while it is out).
       */
      function partyState(done:Function):void;

      /**
       * n (or -n) of the 道具 id: done(count) with the count now, or done(-1) if refused. shown
       * (API 4): what is got (n > 0) is shown in the game's own window, as a boss's 亚比蛋 is.
       */
      function giveItem(id:int, n:int = 1, done:Function = null, shown:Boolean = true):void;

      /**
       * Show the player as look in the mod's rooms: a race (a 亚比 of the game or the mod's),
       * "npc:<id>" (an NPC of the game), a DisplayObject or a Class; null: as the player is.
       * name: the name shown under the player there instead of the player's (null: the player's).
       */
      function playerLook(look:*, name:String = null):void;

      /**
       * (API 4) A picture of the game: a new className of the game's file (as the game's own
       * modules load them, "fbteam/fbsiwude_res"), given to done(DisplayObject), or done(null).
       */
      function gameArt(file:String, className:String, done:Function):void;
   }
}
