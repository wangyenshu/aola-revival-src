package mmo.game.parkour.game.player.state
{
   import mmo.game.parkour.game.interfaces.IParkourPlayerState;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.game.player.ParkourPlayerStateType;
   import mmo.game.parkour.game.road.ParkourRoad;
   
   public class ParkourPlayerDieState implements IParkourPlayerState
   {
      
      private var player:ParkourPlayer;
      
      public function ParkourPlayerDieState(param1:ParkourPlayer)
      {
         super();
         this.player = param1;
      }
      
      public function onChange() : void
      {
      }
      
      public function moveYOnRoad(param1:ParkourRoad) : void
      {
      }
      
      public function jump(param1:int) : void
      {
      }
      
      public function lieDown() : void
      {
      }
      
      public function rise() : void
      {
      }
      
      public function fly() : void
      {
         this.player.changeState(ParkourPlayerStateType.Fly);
      }
      
      public function land() : void
      {
      }
      
      public function dispose() : void
      {
         this.player = null;
      }
   }
}

