package mmo.play.player.movable.strategy
{
   import mmo.play.player.movable.IMovable;

   /** REBUILT. Common base of the moving strategies. */
   public class AbstractMovingStrategy implements IMovingStrategy
   {
      protected var _controlItem:IMovable;

      public function AbstractMovingStrategy()
      {
         super();
      }

      public function setControlItem(item:IMovable):void
      {
         _controlItem = item;
      }

      public function dispose():void
      {
         _controlItem = null;
      }
   }
}
