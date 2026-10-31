package mmo.game.parkour.game.interfaces
{
   import mmo.game.parkour.game.road.ParkourRoad;
   
   public interface IParkourPlayerState
   {
      
      function onChange() : void;
      
      function moveYOnRoad(param1:ParkourRoad) : void;
      
      function jump(param1:int) : void;
      
      function lieDown() : void;
      
      function rise() : void;
      
      function fly() : void;
      
      function land() : void;
      
      function dispose() : void;
   }
}

