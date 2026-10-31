package mmo.game.parkour.game.road
{
   import flash.display.MovieClip;
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.data.mapitem.ParkourRoadInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRoad extends ParkourAbstractMapItemManager
   {
      
      private var _totalMoveDistance:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourRoad()
      {
         super([ParkourGameMapConfig.Road,ParkourGameMapConfig.RoadFiller]);
      }
      
      override protected function onMove(param1:int) : void
      {
         this.AddTotalMoveDistance(param1);
      }
      
      override protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         return new ParkourRoadPart(param1 as ParkourRoadInfo,param2);
      }
      
      override protected function onBuildOver() : void
      {
         var _loc2_:ParkourRoadPart = null;
         var _loc3_:int = 0;
         var _loc1_:int = 0;
         while(_loc1_ < items.length)
         {
            _loc2_ = this.getRoadPart(_loc1_);
            _loc3_ = ParkourRoadPart.Location_Head;
            if(this.hadPreRoad(_loc2_))
            {
               if(this.hadNextRoad(_loc2_))
               {
                  _loc3_ = ParkourRoadPart.Location_Middle;
               }
               else
               {
                  _loc3_ = ParkourRoadPart.Location_End;
               }
            }
            else if(this.hadNextRoad(_loc2_))
            {
               _loc3_ = ParkourRoadPart.Location_Head;
            }
            else
            {
               _loc3_ = ParkourRoadPart.Location_Single;
            }
            _loc2_.setLocation(_loc3_);
            _loc1_++;
         }
      }
      
      private function hadPreRoad(param1:ParkourRoadPart) : Boolean
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = this.getRoadPart(_loc2_);
            if(_loc3_.info.type == ParkourGameMapConfig.Road && ParkourHelper.isNear(_loc3_.y,param1.y) && ParkourHelper.isNear(param1.x - _loc3_.x,param1.width,10))
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      private function hadNextRoad(param1:ParkourRoadPart) : Boolean
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = this.getRoadPart(_loc2_);
            if(_loc3_.info.type == ParkourGameMapConfig.Road && ParkourHelper.isNear(_loc3_.y,param1.y) && ParkourHelper.isNear(_loc3_.x - param1.x,param1.width,10))
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      private function getRoadPart(param1:int) : ParkourRoadPart
      {
         if(param1 < 0 || param1 >= items.length)
         {
            return null;
         }
         return items[param1] as ParkourRoadPart;
      }
      
      public function getRoadY(param1:int) : int
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(_loc3_.isInThisRoad(param1))
            {
               return _loc3_.getRoadTop();
            }
            _loc2_++;
         }
         return ParkourGameConfig.Height;
      }
      
      public function isUnderEmptyRoadFiller(param1:ParkourAbstractMapItem) : Boolean
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(_loc3_.isInThisRoad(param1.x) && _loc3_.y <= param1.y)
            {
               if(_loc3_.info.type == ParkourGameMapConfig.RoadFiller)
               {
                  return true;
               }
            }
            _loc2_++;
         }
         return false;
      }
      
      public function isHitPlayerBottom(param1:ParkourPlayer) : ParkourRoadPart
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(param1.isHitBottom(_loc3_))
            {
               return _loc3_;
            }
            _loc2_++;
         }
         return null;
      }
      
      public function isNearPlayerBottom(param1:ParkourPlayer) : ParkourRoadPart
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(param1.isHitBottom(_loc3_,param1.param.speedY))
            {
               return _loc3_;
            }
            _loc2_++;
         }
         return null;
      }
      
      public function isHinderPlayer(param1:ParkourPlayer) : Boolean
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(param1.isHitRight(_loc3_) && param1.y > _loc3_.y)
            {
               return true;
            }
            _loc2_++;
         }
         return false;
      }
      
      public function get totalMoveDistance() : int
      {
         return this._totalMoveDistance.getValue();
      }
      
      private function AddTotalMoveDistance(param1:int) : void
      {
         this._totalMoveDistance.add(Math.abs(param1));
      }
      
      public function get totalMoveMeter() : int
      {
         return this.totalMoveDistance / ParkourGameConfig.MeterToPixel;
      }
      
      public function checkFillEmptyRoad() : void
      {
         var _loc3_:ParkourRoadPart = null;
         var _loc4_:int = 0;
         var _loc5_:ParkourRoadPart = null;
         var _loc6_:int = 0;
         var _loc1_:Array = [];
         var _loc2_:int = 0;
         while(_loc2_ < items.length)
         {
            _loc3_ = items[_loc2_] as ParkourRoadPart;
            if(_loc3_.x <= ParkourGameConfig.Width)
            {
               _loc4_ = _loc3_.x + _loc3_.width;
               _loc5_ = this.getNextRoadPart(_loc3_);
               if(_loc5_ != null)
               {
                  _loc6_ = (_loc5_.x - _loc4_) / ParkourGameMapConfig.Interval_Width;
                  if(_loc6_ > 0)
                  {
                     _loc1_.push({
                        "firstX":_loc4_,
                        "y":_loc3_.y,
                        "fillNum":_loc6_
                     });
                  }
               }
            }
            _loc2_++;
         }
         this.fillEmptyRoads(_loc1_);
      }
      
      private function fillEmptyRoads(param1:Array) : void
      {
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            _loc3_ = param1[_loc2_] as Object;
            _loc4_ = int(_loc3_.firstX);
            _loc5_ = int(_loc3_.y);
            _loc6_ = int(_loc3_.fillNum);
            this.fillOnceEmptyRoad(_loc4_,_loc5_,_loc6_);
            _loc2_++;
         }
      }
      
      private function fillOnceEmptyRoad(param1:int, param2:int, param3:int) : void
      {
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < param3)
         {
            _loc5_ = param1 + _loc4_ * ParkourGameMapConfig.Interval_Width;
            create(ParkourGameMapConfig.RoadFiller,_loc5_,param2);
            _loc4_++;
         }
      }
      
      private function getNextRoadPart(param1:ParkourRoadPart) : ParkourRoadPart
      {
         var _loc5_:ParkourRoadPart = null;
         var _loc2_:int = param1.x;
         var _loc3_:ParkourRoadPart = null;
         var _loc4_:int = 0;
         while(_loc4_ < items.length)
         {
            _loc5_ = items[_loc4_] as ParkourRoadPart;
            if(_loc5_.x > _loc2_)
            {
               if(_loc3_ == null || _loc5_.x < _loc3_.x)
               {
                  _loc3_ = _loc5_;
               }
            }
            _loc4_++;
         }
         return _loc3_;
      }
   }
}

