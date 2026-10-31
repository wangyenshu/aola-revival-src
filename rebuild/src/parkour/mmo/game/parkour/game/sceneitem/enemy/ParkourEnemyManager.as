package mmo.game.parkour.game.sceneitem.enemy
{
   import flash.display.MovieClip;
   import mmo.game.parkour.dailytask.ParkourDailyTaskLogger;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourEnemyInfo;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.player.ParkourPlayer;
   
   public class ParkourEnemyManager extends ParkourAbstractMapItemManager
   {
      
      private static const MinMissileCreateMeter:int = 5000;
      
      private static const MissileCreateDelayMetersArray:Array = [{
         "maxMeter":40000,
         "delayMeter":2000
      },{
         "maxMeter":int.MAX_VALUE,
         "delayMeter":1000
      }];
      
      private var logMissileCreateMeter:int;
      
      private var hadLogJumpMissile:Boolean = true;
      
      public function ParkourEnemyManager()
      {
         super([ParkourGameMapConfig.Enemy,ParkourGameMapConfig.EnemySpine,ParkourGameMapConfig.EnemyMissile]);
      }
      
      override protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         if(param1.type == ParkourGameMapConfig.EnemyMissile)
         {
            this.hadLogJumpMissile = false;
         }
         return new ParkourEnemy(param1 as ParkourEnemyInfo,param2);
      }
      
      public function checkHitPlayer(param1:ParkourPlayer) : void
      {
         var _loc2_:ParkourEnemy = null;
         var _loc3_:int = 0;
         for each(_loc2_ in items)
         {
            if(!(_loc2_.isDestroyed() || _loc2_.canDispose()))
            {
               if(param1.isHit(_loc2_))
               {
                  if(param1.param.invincible || _loc2_.canDestroy && param1.isHitBottom(_loc2_))
                  {
                     _loc2_.destroy();
                     param1.addScore(_loc2_.info.score);
                     if(_loc2_.canDestroy && param1.isHitBottom(_loc2_))
                     {
                        param1.param.jumpTime = 0;
                        param1.jump();
                     }
                  }
                  if(!param1.isHitBottom(_loc2_) && param1.isHitRight(_loc2_) || !_loc2_.canDestroy && param1.isHitBottom(_loc2_))
                  {
                     param1.die();
                  }
                  break;
               }
               if(!this.hadLogJumpMissile && _loc2_.type == ParkourGameMapConfig.EnemyMissile)
               {
                  _loc3_ = param1.x - 0.5 * _loc2_.getRect().width;
                  if(_loc2_.x <= _loc3_)
                  {
                     this.hadLogJumpMissile = true;
                     ParkourDailyTaskLogger.instance.logJumpMissile();
                  }
               }
            }
         }
      }
      
      public function destroyScreenEnemy() : void
      {
         var _loc1_:ParkourEnemy = null;
         for each(_loc1_ in items)
         {
            if(!(_loc1_.isDestroyed() || _loc1_.canDispose()))
            {
               if(ParkourGameConfig.MapRect.contains(_loc1_.x,_loc1_.y))
               {
                  _loc1_.destroy();
               }
            }
         }
      }
      
      public function destroyEnemyUnderEmptyRoadFiller() : void
      {
         var _loc1_:ParkourEnemy = null;
         for each(_loc1_ in items)
         {
            if(!(_loc1_.isDestroyed() || _loc1_.canDispose()))
            {
               if(ParkourGameScene.instance.getRoad().isUnderEmptyRoadFiller(_loc1_))
               {
                  _loc1_.destroy();
               }
            }
         }
      }
      
      public function checkCreateMissile(param1:int) : void
      {
         if(param1 < MinMissileCreateMeter)
         {
            return;
         }
         var _loc2_:int = this.getMissileCreateDelay(param1);
         if(this.logMissileCreateMeter == 0 || param1 - this.logMissileCreateMeter > _loc2_)
         {
            this.logMissileCreateMeter = param1;
            create(ParkourGameMapConfig.EnemyMissile,1000,350);
         }
      }
      
      private function getMissileCreateDelay(param1:int) : int
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         for each(_loc2_ in MissileCreateDelayMetersArray)
         {
            _loc3_ = int(_loc2_.maxMeter);
            if(param1 < _loc3_)
            {
               return _loc2_.delayMeter;
            }
         }
         return -1;
      }
   }
}

