package mmo.game.parkour.game.mapitem.move
{
   import mmo.game.parkour.game.interfaces.IParkourMapItemMoveStrategy;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourMoveFastThanMapStrategy implements IParkourMapItemMoveStrategy
   {
      
      private var item:ParkourAbstractMapItem;
      
      public function ParkourMoveFastThanMapStrategy()
      {
         super();
      }
      
      public function setControlItem(param1:ParkourAbstractMapItem) : void
      {
         this.item = param1;
      }
      
      public function move(param1:int) : void
      {
         this.item.x += param1 - 10;
      }
      
      public function dispose() : void
      {
         this.item = null;
      }
   }
}

