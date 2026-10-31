package mmo.game.parkour.game.interfaces
{
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public interface IParkourMapItemMoveStrategy
   {
      
      function setControlItem(param1:ParkourAbstractMapItem) : void;
      
      function move(param1:int) : void;
      
      function dispose() : void;
   }
}

