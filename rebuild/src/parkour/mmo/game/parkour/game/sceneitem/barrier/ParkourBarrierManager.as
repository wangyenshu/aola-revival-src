package mmo.game.parkour.game.sceneitem.barrier
{
   import flash.display.MovieClip;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourBarrierInfo;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourBarrierManager extends ParkourAbstractMapItemManager
   {
      
      public function ParkourBarrierManager()
      {
         super([ParkourGameMapConfig.Barrier0]);
      }
      
      override protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         return new ParkourBarrier(param1 as ParkourBarrierInfo,param2);
      }
      
      public function isHitPlayerRight(param1:ParkourPlayer) : Boolean
      {
         var _loc2_:ParkourBarrier = null;
         for each(_loc2_ in items)
         {
            if(!_loc2_.isDestroyed() && !_loc2_.canDispose() && param1.isHitRight(_loc2_))
            {
               if(param1.param.invincible)
               {
                  _loc2_.destroy();
                  param1.addScore(_loc2_.info.score);
               }
               return true;
            }
         }
         return false;
      }
      
      public function checkHitPlayerTop(param1:ParkourPlayer) : Boolean
      {
         var _loc2_:ParkourBarrier = null;
         for each(_loc2_ in items)
         {
            if(!_loc2_.isDestroyed() && !_loc2_.canDispose() && param1.isHitTop(_loc2_))
            {
               if(_loc2_.canDestroy || param1.param.invincible)
               {
                  _loc2_.destroy();
                  param1.addScore(_loc2_.info.score);
               }
               param1.drop();
               return true;
            }
         }
         return false;
      }
      
      public function isNearBottom(param1:ParkourPlayer) : Boolean
      {
         var _loc2_:ParkourBarrier = null;
         var _loc3_:Boolean = false;
         for each(_loc2_ in items)
         {
            if(!_loc2_.isDestroyed() && !_loc2_.canDispose())
            {
               _loc3_ = ParkourHelper.inInRange(param1.x,_loc2_.getRect().x,_loc2_.getRect().width) || ParkourHelper.inInRange(_loc2_.x,param1.getRect().x,param1.getRect().width);
               if(_loc3_ && ParkourHelper.isNear(param1.getRect().top,_loc2_.getRect().bottom,15))
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public function checkHitPlayerBottom(param1:ParkourPlayer) : Boolean
      {
         return false;
      }
   }
}

