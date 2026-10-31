package mmo.game.parkour.game.sceneitem.prop
{
   import flash.display.MovieClip;
   import mmo.game.parkour.dailytask.ParkourDailyTaskLogger;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.data.mapitem.ParkourPropInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.mapitem.move.ParkourMoveToPlayerStrategy;
   import mmo.game.parkour.game.player.ParkourPlayer;
   
   public class ParkourPropManager extends ParkourAbstractMapItemManager
   {
      
      private var logCreateMeterMap:Object = {};
      
      public function ParkourPropManager()
      {
         super([ParkourGameMapConfig.PropGoldCoin,ParkourGameMapConfig.PropFly,ParkourGameMapConfig.PropPower,ParkourGameMapConfig.PropAbsore]);
      }
      
      override protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         return new ParkourProp(param1 as ParkourPropInfo,param2);
      }
      
      public function checkCreateByMapMeter(param1:int, param2:Number, param3:Number) : void
      {
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:ParkourPropInfo = null;
         var _loc4_:Array = getItemTypes();
         var _loc5_:int = 0;
         while(_loc5_ < _loc4_.length)
         {
            _loc6_ = int(_loc4_[_loc5_]);
            _loc7_ = int(this.logCreateMeterMap[_loc6_]);
            _loc8_ = ParkourGameMapConfig.getMapPartInfo(_loc6_) as ParkourPropInfo;
            if(param1 >= _loc8_.minCreateMeter)
            {
               if(_loc7_ == 0 || param1 - _loc7_ > _loc8_.createDelayMeter)
               {
                  this.logCreateMeterMap[_loc6_] = param1;
                  create(_loc6_,param2,param3);
                  break;
               }
            }
            _loc5_++;
         }
      }
      
      public function checkAbsorbByPlayer(param1:ParkourPlayer) : void
      {
         var _loc2_:ParkourProp = null;
         if(!param1.param.absorbing)
         {
            return;
         }
         for each(_loc2_ in items)
         {
            if(!_loc2_.isAbsorbing && ParkourGameConfig.MapRect.intersects(_loc2_.getRect()))
            {
               _loc2_.setMoveStrategy(new ParkourMoveToPlayerStrategy());
               _loc2_.isAbsorbing = true;
            }
         }
      }
      
      public function checkHitPlayer(param1:ParkourPlayer) : void
      {
         var _loc2_:ParkourProp = null;
         for each(_loc2_ in items)
         {
            if(!_loc2_.canDispose() && param1.isHit(_loc2_))
            {
               _loc2_.signDispose();
               ParkourDailyTaskLogger.instance.logHitProp(_loc2_.type);
               ParkourGameScene.instance.getEffectManager().excuteEffect(_loc2_.effectClass,_loc2_.effectParams);
            }
         }
      }
   }
}

