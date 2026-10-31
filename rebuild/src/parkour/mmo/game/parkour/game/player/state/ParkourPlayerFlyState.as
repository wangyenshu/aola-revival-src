package mmo.game.parkour.game.player.state
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.avatar.AvatarActionCodeHelper;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.effect.impl.ParkourPlayerAbsoreEffect;
   import mmo.game.parkour.game.interfaces.IParkourPlayerState;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.game.player.ParkourPlayerStateType;
   import mmo.game.parkour.game.road.ParkourRoad;
   
   public class ParkourPlayerFlyState implements IParkourPlayerState
   {
      
      private var isLand:Boolean = false;
      
      private var player:ParkourPlayer;
      
      private var logMapSpeedOfMeter:int;
      
      public function ParkourPlayerFlyState(param1:ParkourPlayer)
      {
         super();
         this.player = param1;
      }
      
      public function onChange() : void
      {
         this.player.action(AvatarActionCodeHelper.SPRINT);
         ParkourGameScene.instance.speedUp();
         this.isLand = false;
         this.player.param.invincible = true;
         this.player.y = ParkourGameConfig.Height / 2;
         this.player.param.absorbing = true;
         ParkourGameScene.instance.getEffectManager().stopAndDelEffect(ParkourPlayerAbsoreEffect);
      }
      
      public function moveYOnRoad(param1:ParkourRoad) : void
      {
         ParkourGameScene.instance.getEnemyManager().destroyScreenEnemy();
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
      }
      
      public function land() : void
      {
         this.player.param.invincible = false;
         this.player.param.absorbing = false;
         this.player.param.speedY = 0;
         this.isLand = true;
         ParkourGameScene.instance.resumeSpeed();
         ParkourGameScene.instance.getRoad().checkFillEmptyRoad();
         this.player.changeState(ParkourPlayerStateType.Jump);
      }
      
      public function dispose() : void
      {
      }
   }
}

