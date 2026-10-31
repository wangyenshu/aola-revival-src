package mmo.game.parkour.game.player.state
{
   import mmo.game.parkour.game.avatar.AvatarActionCodeHelper;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourPlayerState;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.game.player.ParkourPlayerStateType;
   import mmo.game.parkour.game.road.ParkourRoad;
   import mmo.game.parkour.game.road.ParkourRoadPart;
   
   public class ParkourPlayerJumpState implements IParkourPlayerState
   {
      
      private var player:ParkourPlayer;
      
      public function ParkourPlayerJumpState(param1:ParkourPlayer)
      {
         super();
         this.player = param1;
      }
      
      public function onChange() : void
      {
         this.player.action(AvatarActionCodeHelper.JUMP_UP);
         this.player.param.jumpTime = 1;
      }
      
      public function moveYOnRoad(param1:ParkourRoad) : void
      {
         var _loc3_:int = 0;
         var _loc4_:ParkourRoadPart = null;
         var _loc5_:int = 0;
         if(this.player.param.speedY >= 0)
         {
            this.player.action(AvatarActionCodeHelper.JUMP_DOWN);
         }
         var _loc2_:ParkourRoadPart = param1.isHitPlayerBottom(this.player);
         if(_loc2_ != null && this.player.param.speedY > 0)
         {
            _loc3_ = _loc2_.getRoadTop();
            this.player.y = _loc3_;
            this.player.param.jumpTime = 0;
            this.player.changeState(ParkourPlayerStateType.Run);
         }
         else
         {
            _loc4_ = param1.isNearPlayerBottom(this.player);
            if(this.player.param.speedY > 0 && _loc4_ != null)
            {
               _loc5_ = _loc4_.getRoadTop();
               this.player.y = _loc5_;
               this.player.param.jumpTime = 0;
               this.player.changeState(ParkourPlayerStateType.Run);
            }
            else
            {
               this.player.y += this.player.param.speedY;
               this.player.param.speedY += ParkourPlayer.AccY;
            }
         }
         if(this.player.y <= 120)
         {
            this.player.drop();
         }
         if(this.player.y >= ParkourGameConfig.Height)
         {
            this.player.die();
         }
      }
      
      public function jump(param1:int) : void
      {
         if(this.player.param.jumpTime < this.player.param.maxJumpTime)
         {
            if(this.player.param.jumpTime == 0)
            {
               this.player.action(AvatarActionCodeHelper.JUMP_UP);
            }
            else
            {
               this.player.action(AvatarActionCodeHelper.JUMP_ON_AIR);
            }
            ++this.player.param.jumpTime;
            this.player.param.speedY = param1;
         }
      }
      
      public function lieDown() : void
      {
      }
      
      public function fly() : void
      {
         this.player.param.jumpTime = 0;
         this.player.changeState(ParkourPlayerStateType.Fly);
      }
      
      public function rise() : void
      {
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

