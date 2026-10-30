package mmo.play.player.movable.strategy
{
   import mmo.interfaces.IDispose;
   import mmo.play.player.movable.IMovable;

   /** REBUILT. Decides where a movable goes (mouse control, following, wandering). */
   public interface IMovingStrategy extends IDispose
   {
      function setControlItem(item:IMovable):void;
   }
}
