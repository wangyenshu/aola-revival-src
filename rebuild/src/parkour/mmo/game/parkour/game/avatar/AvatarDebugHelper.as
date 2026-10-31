package mmo.game.parkour.game.avatar
{
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.geom.Rectangle;
   import mmo.common.DisplayUtil;
   import mmo.common.event.EnterFrameManager;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.loader.LoaderContainer;
   
   public class AvatarDebugHelper
   {
      
      private var _bebug:Boolean = false;
      
      private var debugViewContainer:Sprite = null;
      
      public function AvatarDebugHelper()
      {
         super();
      }
      
      public function openDebug(param1:Function) : void
      {
         if(!this._bebug)
         {
            return;
         }
         this.debugViewContainer = new Sprite();
         LoaderContainer.instance.stage.addChild(this.debugViewContainer);
         EnterFrameManager.instance.register(this.onDebugUpdate,[param1]);
      }
      
      private function onDebugUpdate(param1:Function) : void
      {
         ParkourHelper.clearContainer(this.debugViewContainer);
         var _loc2_:Rectangle = param1.apply();
         var _loc3_:Shape = new Shape();
         var _loc4_:Graphics = _loc3_.graphics;
         _loc4_.lineStyle(2,16711680);
         _loc4_.moveTo(_loc2_.x,_loc2_.y);
         _loc4_.lineTo(_loc2_.x + _loc2_.width,_loc2_.y);
         _loc4_.lineTo(_loc2_.x + _loc2_.width,_loc2_.y + _loc2_.height);
         _loc4_.lineTo(_loc2_.x,_loc2_.y + _loc2_.height);
         _loc4_.lineTo(_loc2_.x,_loc2_.y);
         this.debugViewContainer.addChild(_loc3_);
      }
      
      public function closeDebug() : void
      {
         if(!this._bebug)
         {
            return;
         }
         EnterFrameManager.instance.remove(this.onDebugUpdate);
         DisplayUtil.stopAndRemove(this.debugViewContainer);
         this.debugViewContainer = null;
      }
   }
}

