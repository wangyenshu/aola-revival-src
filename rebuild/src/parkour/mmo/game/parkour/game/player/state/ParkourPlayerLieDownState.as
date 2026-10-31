package mmo.game.parkour.game.player.state
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.avatar.AvatarActionCodeHelper;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourPlayerState;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.game.player.ParkourPlayerStateType;
   import mmo.game.parkour.game.road.ParkourRoad;
   import mmo.game.parkour.game.road.ParkourRoadPart;
   
   public class ParkourPlayerLieDownState implements IParkourPlayerState
   {
      
      private var player:ParkourPlayer;
      
      private var isRising:Boolean = false;
      
      public function ParkourPlayerLieDownState(param1:ParkourPlayer)
      {
         super();
         this.player = param1;
      }
      
      public function onChange() : void
      {
         this.isRising = false;
         this.player.action(AvatarActionCodeHelper.SLIP);
         this.player.param.speedY = 0;
      }
      
      public function moveYOnRoad(param1:ParkourRoad) : void
      {
         var _loc3_:int = 0;
         if(this.isRising)
         {
            if(!ParkourGameScene.instance.getBarrierManager().isNearBottom(this.player))
            {
               this.player.changeState(ParkourPlayerStateType.Run);
            }
         }
         var _loc2_:ParkourRoadPart = param1.isHitPlayerBottom(this.player);
         if(_loc2_ != null)
         {
            _loc3_ = _loc2_.getRoadTop();
            this.player.y = _loc3_;
         }
         else
         {
            this.player.y += this.player.param.speedY;
            this.player.param.speedY += ParkourPlayer.AccY;
         }
         if(this.player.y >= ParkourGameConfig.Height)
         {
            this.player.die();
         }
      }
      
      public function jump(param1:int) : void
      {
         this.player.param.speedY = param1;
         this.player.changeState(ParkourPlayerStateType.Jump);
      }
      
      public function lieDown() : void
      {
      }
      
      public function rise() : void
      {
         this.isRising = true;
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

