package mmo.game.parkour.game.mapitem
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   
   public class ParkourAbstractMapItemManager
   {
      
      private var container:Sprite;
      
      protected var items:Array = [];
      
      private var itemTypes:Array = [];
      
      private var pools:Array = [];
      
      public function ParkourAbstractMapItemManager(param1:Array)
      {
         super();
         this.container = new Sprite();
         this.itemTypes = param1;
      }
      
      protected function getItemTypes() : Array
      {
         return this.itemTypes;
      }
      
      public function create(param1:int, param2:Number, param3:Number) : Boolean
      {
         var _loc4_:ParkourAbstractMapItem = null;
         if(this.itemTypes.indexOf(param1) != -1)
         {
            _loc4_ = this.getItemFromPool(param1);
            _loc4_.x = param2;
            _loc4_.y = param3;
            _loc4_.reset();
            this.container.addChild(_loc4_.view);
            this.items.push(_loc4_);
            return true;
         }
         return false;
      }
      
      public function buildOver() : void
      {
         this.onBuildOver();
      }
      
      protected function onBuildOver() : void
      {
      }
      
      public function move(param1:int) : void
      {
         var _loc2_:ParkourAbstractMapItem = null;
         for each(_loc2_ in this.items)
         {
            _loc2_.move(param1);
            if(_loc2_.x < 0 - _loc2_.view.width * 2)
            {
               _loc2_.signDispose();
            }
         }
         this.onMove(param1);
      }
      
      protected function onMove(param1:int) : void
      {
      }
      
      public function getContainer() : Sprite
      {
         return this.container;
      }
      
      public function checkDispose() : void
      {
         var _loc2_:ParkourAbstractMapItem = null;
         var _loc1_:* = int(this.items.length - 1);
         while(_loc1_ >= 0)
         {
            _loc2_ = this.items[_loc1_] as ParkourAbstractMapItem;
            if(_loc2_.canDispose())
            {
               this.items.splice(_loc1_,1);
               this.disposeItem(_loc2_);
            }
            _loc1_--;
         }
         this.onCheckDispose();
      }
      
      protected function onCheckDispose() : void
      {
      }
      
      final protected function disposeItem(param1:ParkourAbstractMapItem) : void
      {
         var _loc2_:Array = this.getPoolByType(param1.type);
         param1.disposeToPool();
         _loc2_.push(param1);
      }
      
      final protected function getItemFromPool(param1:int) : ParkourAbstractMapItem
      {
         var _loc4_:ParkourMapItemInfo = null;
         var _loc5_:int = 0;
         var _loc6_:MovieClip = null;
         var _loc2_:Array = this.getPoolByType(param1);
         var _loc3_:ParkourAbstractMapItem = _loc2_.shift() as ParkourAbstractMapItem;
         if(_loc3_ == null)
         {
            _loc4_ = ParkourGameMapConfig.getMapPartInfo(param1);
            _loc5_ = ParkourGameScene.instance.getField();
            _loc6_ = ParkourGameResConfig.createViewOfMapItemByType(_loc5_,param1) as MovieClip;
            _loc3_ = this.newInstance(_loc4_,_loc6_);
         }
         return _loc3_;
      }
      
      private function getPoolByType(param1:int) : Array
      {
         var _loc2_:Array = this.pools[param1] as Array;
         if(_loc2_ == null)
         {
            _loc2_ = [];
            this.pools[param1] = _loc2_;
         }
         return _loc2_;
      }
      
      protected function newInstance(param1:ParkourMapItemInfo, param2:MovieClip) : ParkourAbstractMapItem
      {
         throw new Error("newInstance need override");
      }
      
      private function diposeItems(param1:Array) : void
      {
         var _loc2_:ParkourAbstractMapItem = null;
         for each(_loc2_ in param1)
         {
            _loc2_.dispose();
         }
      }
      
      protected function onDispose() : void
      {
      }
      
      public function dispose() : void
      {
         var _loc1_:Array = null;
         this.onDispose();
         this.diposeItems(this.items);
         for each(_loc1_ in this.pools)
         {
            this.diposeItems(_loc1_);
         }
         this.items = [];
         this.pools = [];
      }
   }
}

