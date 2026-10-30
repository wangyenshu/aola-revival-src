package mmo.play.scene.helper.draganddrop
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import mmo.loader.LoaderContainer;
   import mmo.play.player.PlayerManager;
   
   /**
    * LATER class (the live play.swf's mmo.play.scene.helper.draganddrop,
    * decompiled; code unchanged). Drag-and-drop interactions of the 2012
    * story quests whose scripts survive only as later uploads (tasks 2443,
    * 2468, 2583, 2773, 2812).
    */
   public class DragAndDropHelper
   {
      
      private static var _instance:DragAndDropHelper;
      
      private var _targetTable:Dictionary;
      
      public function DragAndDropHelper()
      {
         super();
         if(_instance != null)
         {
            throw new Error("DragAndDropHelper is implements as Singleton!!");
         }
         this._targetTable = new Dictionary();
      }
      
      public static function get instance() : DragAndDropHelper
      {
         if(_instance == null)
         {
            _instance = new DragAndDropHelper();
         }
         return _instance;
      }
      
      public function registerTarget(param1:Sprite, param2:DisplayObject, param3:Function, param4:int = -1, param5:Rectangle = null, param6:Boolean = false, param7:Boolean = true, param8:Function = null) : void
      {
         if(param1 == null || param1.parent == null || param2 == null || param2.parent == null)
         {
            throw new Error("可以拖动的元件和击中区域，两者必须有父亲且不能为空！");
         }
         if(param3 == null)
         {
            throw new Error("击中后的回调不能为空!");
         }
         if(this._targetTable[param1] != null)
         {
            throw new Error("重复注册的DragAndDrop目标！");
         }
         var _loc9_:Object = new Object();
         _loc9_.objToDrag = param1;
         _loc9_.hitObj = param2;
         _loc9_.onHit = param3;
         _loc9_.onMiss = param8;
         _loc9_.removeOnHit = param6;
         _loc9_.resetOnMiss = param7;
         _loc9_.initX = param1.x;
         _loc9_.initY = param1.y;
         _loc9_.buttonMode = param1.buttonMode;
         _loc9_.dist = param4 <= 0 ? 20 : param4;
         _loc9_.bounds = param5 == null ? LoaderContainer.instance.stage : param5;
         this._targetTable[param1] = _loc9_;
         param1.buttonMode = true;
         param1.mouseChildren = false;
         param1.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
         param1.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
         param1.addEventListener(MouseEvent.CLICK,this.onMouseClick);
         param2.addEventListener(Event.REMOVED_FROM_STAGE,this.onHitObjRemoveFromStage);
         param1.addEventListener(Event.REMOVED_FROM_STAGE,this.onDragObjRemoveFromStage);
      }
      
      public function removeTarget(param1:Sprite) : void
      {
         if(param1 == null || this._targetTable[param1] == null)
         {
            return;
         }
         this.disposeTarget(this._targetTable[param1]);
         delete this._targetTable[param1];
      }
      
      private function onHitObjRemoveFromStage(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
         _loc2_.addEventListener(Event.REMOVED_FROM_STAGE,this.onHitObjRemoveFromStage);
         for each(_loc3_ in this._targetTable)
         {
            if(_loc3_.hitObj == _loc2_)
            {
               this.disposeTarget(_loc3_);
               break;
            }
         }
      }
      
      private function onDragObjRemoveFromStage(param1:Event) : void
      {
         var _loc2_:InteractiveObject = param1.target as InteractiveObject;
         var _loc3_:Object = this._targetTable[_loc2_];
         this.disposeTarget(_loc3_);
      }
      
      private function onMouseDown(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         var _loc2_:Sprite = param1.currentTarget as Sprite;
         _loc2_.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
         _loc2_.startDrag(false,this._targetTable[_loc2_].bounds as Rectangle);
         PlayerManager.getInstance().myPlayer.movability = false;
      }
      
      private function onMouseUp(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         var _loc2_:Sprite = param1.target as Sprite;
         _loc2_.stopDrag();
         var _loc3_:Object = this._targetTable[_loc2_];
         PlayerManager.getInstance().myPlayer.movability = true;
         if(this.isHit(_loc2_,DisplayObject(_loc3_.hitObj)))
         {
            if(Boolean(_loc3_.removeOnHit))
            {
               if(_loc2_.parent != null)
               {
                  _loc2_.parent.removeChild(_loc2_);
               }
               if(_loc3_.hitObj.parent != null)
               {
                  _loc3_.hitObj.parent.removeChild(_loc3_.hitObj);
               }
            }
            this.disposeTarget(_loc3_);
            delete this._targetTable[_loc2_];
            (_loc3_.onHit as Function).apply(null,[_loc2_,_loc3_.hitObj]);
            return;
         }
         if(Boolean(_loc3_.resetOnMiss))
         {
            _loc2_.x = _loc3_.initX;
            _loc2_.y = _loc3_.initY;
         }
         if(_loc3_.onMiss != null)
         {
            (_loc3_.onMiss as Function).apply(null,[_loc2_,_loc3_.hitObj]);
         }
      }
      
      private function onMouseClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         param1.stopPropagation();
      }
      
      private function isHit(param1:DisplayObject, param2:DisplayObject) : Boolean
      {
         var _loc3_:Number = param1.x - param2.x;
         var _loc4_:Number = param1.y - param2.y;
         var _loc5_:Number = Number(this._targetTable[param1].dist);
         _loc5_ *= _loc5_;
         _loc3_ *= _loc3_;
         _loc4_ *= _loc4_;
         if(_loc3_ + _loc4_ < _loc5_)
         {
            return true;
         }
         return false;
      }
      
      private function disposeTarget(param1:Object) : void
      {
         var _loc2_:Sprite = param1.objToDrag as Sprite;
         var _loc3_:DisplayObject = param1.hitObj as DisplayObject;
         _loc2_.stopDrag();
         _loc3_.removeEventListener(Event.REMOVED_FROM_STAGE,this.onHitObjRemoveFromStage);
         _loc2_.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
         _loc2_.removeEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
         _loc2_.removeEventListener(Event.REMOVED_FROM_STAGE,this.onDragObjRemoveFromStage);
         _loc2_.buttonMode = Boolean(param1.buttonMode);
      }
   }
}

