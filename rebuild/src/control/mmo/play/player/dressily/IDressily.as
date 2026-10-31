package mmo.play.player.dressily
{
   import flash.display.DisplayObject;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.play.player.dressily.mstate.IMovingState;

   /** REBUILT. The dressed avatar of a player: sprite, clothes and actions. */
   public interface IDressily extends IDispose, IEventDispatcher
   {
      function get avatarSprite():DisplayObject;
      function action(code:String):void;
      function currentAction():String;
      function setAvatar(avatar:Object):void;
      function getAvatar():AvatarInfo;
      function get top():Number;
      /** Later scene code (as the later IDressily has it): how the player moves now. */
      function getMovingState():IMovingState;
   }
}
