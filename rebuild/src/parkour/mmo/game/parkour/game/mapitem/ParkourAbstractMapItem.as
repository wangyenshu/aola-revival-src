package mmo.game.parkour.game.mapitem
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.geom.Rectangle;
   import mmo.common.DisplayUtil;
   import mmo.game.parkour.game.data.mapitem.ParkourMapItemInfo;
   import mmo.game.parkour.game.interfaces.IParkourMapItemMoveStrategy;
   import mmo.game.parkour.game.mapitem.move.ParkourMoveWithMapStrategy;
   
   public class ParkourAbstractMapItem
   {
      
      private var _info:ParkourMapItemInfo;
      
      private var _view:DisplayObject;
      
      private var _canDispose:Boolean = false;
      
      private var _moveStrategy:IParkourMapItemMoveStrategy;
      
      private var _mcHitArea:DisplayObject;
      
      public function ParkourAbstractMapItem(param1:ParkourMapItemInfo, param2:DisplayObject)
      {
         super();
         this._info = param1;
         this._view = param2;
         DisplayUtil.stop(param2);
         if(param2 is DisplayObjectContainer)
         {
            this._mcHitArea = (param2 as DisplayObjectContainer).getChildByName("mcHitArea") as DisplayObject;
         }
      }
      
      protected function setDefaultMove() : void
      {
         this.setMoveStrategy(new ParkourMoveWithMapStrategy());
      }
      
      public function setMoveStrategy(param1:IParkourMapItemMoveStrategy) : void
      {
         if(this._moveStrategy != null)
         {
            this._moveStrategy.dispose();
            this._moveStrategy = null;
         }
         this._moveStrategy = param1;
         this._moveStrategy.setControlItem(this);
      }
      
      protected function changeInfoAndView(param1:ParkourMapItemInfo, param2:DisplayObject) : void
      {
         this._info = param1;
         this._view = param2;
      }
      
      public function reset() : void
      {
         this._canDispose = false;
         this.setDefaultMove();
         this.onReset();
      }
      
      protected function onReset() : void
      {
      }
      
      public function move(param1:int) : void
      {
         this._moveStrategy.move(param1);
      }
      
      public function get type() : int
      {
         return this._info.type;
      }
      
      public function get info() : ParkourMapItemInfo
      {
         return this._info;
      }
      
      public function get view() : DisplayObject
      {
         return this._view;
      }
      
      public function getRect() : Rectangle
      {
         if(this._mcHitArea != null)
         {
            return this._mcHitArea.getRect(this._view.parent);
         }
         return this._view.getRect(this._view.parent);
      }
      
      public function get x() : Number
      {
         return this._view.x;
      }
      
      public function set x(param1:Number) : void
      {
         this._view.x = param1;
      }
      
      public function get y() : Number
      {
         return this._view.y;
      }
      
      public function set y(param1:Number) : void
      {
         this._view.y = param1;
      }
      
      public function signDispose() : void
      {
         this._canDispose = true;
      }
      
      public function canDispose() : Boolean
      {
         return this._canDispose;
      }
      
      public function disposeToPool() : void
      {
         DisplayUtil.stopAndRemove(this._view);
      }
      
      protected function onDispose() : void
      {
      }
      
      public function dispose() : void
      {
         this.onDispose();
         this._moveStrategy.dispose();
         DisplayUtil.stopAndRemove(this._view);
         this._view = null;
      }
   }
}

