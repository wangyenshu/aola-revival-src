package mmo.revival.mod
{
   import flash.display.DisplayObject;

   /** A character or opponent of a room (IModRoom.npc, IModRoom.foe). */
   public interface IModNpc
   {
      function get view():DisplayObject;

      /** Its name (as shown under it). */
      function get npcName():String;

      /** A speech bubble over it. */
      function say(text:String, seconds:Number = 3):void;

      /** A conversation with it (IModGame.talk with its name and picture). */
      function talk(pages:Array, done:Function = null):void;

      /** Move to x, y in seconds; then(). */
      function moveTo(x:Number, y:Number, seconds:Number = 1, then:Function = null):void;

      function remove():void;
   }
}
