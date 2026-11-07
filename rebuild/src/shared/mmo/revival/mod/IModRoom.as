package mmo.revival.mod
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.geom.Point;

   /** The room shown (IModGame.currentRoom, and what a room's build function gets). */
   public interface IModRoom
   {
      function get id():String;

      /** The room's width (960 to 2880). */
      function get roomWidth():int;

      /**
       * Put d in the room at x, y. layer: "back" (behind the players), "players"
       * (among them, nearer ones in front), "front" (over them), "screen" (fixed on
       * the screen as the room scrolls). Returns d.
       */
      function add(d:DisplayObject, x:Number = 0, y:Number = 0, layer:String = "back"):DisplayObject;

      function remove(d:DisplayObject):void;

      /**
       * A door: the rectangle x, y, w, h; clicked, the player walks there, then
       * onEnter() (for example game.enter("room2")). label is shown on it;
       * drawn: a light frame is drawn round it.
       */
      function door(x:Number, y:Number, w:Number, h:Number, label:String, onEnter:Function, drawn:Boolean = true):Sprite;

      /**
       * A character. def:
       *   name      shown under it
       *   look      a DisplayObject, a Class, a race (a 亚比 of the game or of the mod), or
       *             (API 4) "npc:<id>": an NPC of the game (its picture in talk() too)
       *   picture   for talk(): DisplayObject, Class or "npc:<id>" (default: look, when not a race)
       *   x, y      where it stands (its feet)
       *   scale     default 1
       *   tip       the mouse's tip (default: name)
       *   onClick   function():void, after the player has walked up to it
       */
      function npc(def:Object):IModNpc;

      /**
       * An opponent: as npc, plus team (as IModGame.fight), heal (default true),
       * boss (drawn larger), onWin, onLose (functions). Beaten, it goes away
       * (until the room is shown again).
       */
      function foe(def:Object):IModNpc;

      /** A speech bubble over d for seconds. */
      function say(d:DisplayObject, text:String, seconds:Number = 3):void;

      /** Where the player stands. */
      function get player():Point;

      /** Walk the player to x, y; then(). */
      function walkTo(x:Number, y:Number, then:Function = null):void;

      /** f() when the room is left. */
      function onLeave(f:Function):void;

      /**
       * (API 4) A piece of the scene a room on the game's art is drawn with (IModGame.room's
       * scene), found by its name ("et1", "btn_general" …), or null.
       */
      function part(name:String):DisplayObject;

      /** (API 4) Whether x, y is off the floor: a wall of the room, or outside it. */
      function blocked(x:Number, y:Number):Boolean;
   }
}
