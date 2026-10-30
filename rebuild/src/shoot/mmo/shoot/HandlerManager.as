package mmo.shoot
{
   import flash.display.DisplayObject;
   import flash.events.MouseEvent;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.util.constants.EventListenerPriority;
   
   public class HandlerManager
   {
      
      private var targets:Object = {};
      
      public function HandlerManager()
      {
         super();
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE,this.onUnloadScene);
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         this.registerHandler(new SceneHandler());
      }
      
      private function onUnloadScene(param1:SceneManagerEvent) : void
      {
         this.clearTarget();
      }
      
      public function registerHandler(param1:IShootTargetHandler) : void
      {
         var _loc2_:String = this.getTargetInfoKey(param1.targetInfo);
         if(this.targets[_loc2_] == null)
         {
         }
         this.targets[_loc2_] = param1;
         this.addTargetEventListner(param1);
      }
      
      private function addTargetEventListner(param1:IShootTargetHandler) : void
      {
         var target:DisplayObject = null;
         var onClickTarget:Function = null;
         var handler:IShootTargetHandler = param1;
         handler.targetInfo.target.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOver);
         handler.targetInfo.target.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOut);
         target = handler.targetInfo.target;
         onClickTarget = function(param1:MouseEvent):void
         {
            if(!ShootService.instance.isReady)
            {
               return;
            }
            if(handler.targetInfo == null)
            {
               target.removeEventListener(MouseEvent.CLICK,onClickTarget,false);
               return;
            }
            param1.stopImmediatePropagation();
            if(handler.validateShoot())
            {
               ShootService.instance.shoot(handler.targetInfo);
            }
         };
         target.addEventListener(MouseEvent.CLICK,onClickTarget,false,EventListenerPriority.THREE);
      }
      
      public function removeTarget(param1:int, param2:String) : void
      {
         var _loc4_:IShootTargetHandler = null;
         var _loc3_:String = param1 + "_" + param2;
         if(this.targets.hasOwnProperty(_loc3_))
         {
            _loc4_ = this.targets[_loc3_] as IShootTargetHandler;
            this.removeTargetEventListner(_loc4_);
            _loc4_.dispose();
            this.targets[_loc3_] = null;
            delete this.targets[_loc3_];
         }
      }
      
      private function removeTargetEventListner(param1:IShootTargetHandler) : void
      {
         param1.targetInfo.target.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOver);
         param1.targetInfo.target.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOut);
      }
      
      public function clearTarget() : void
      {
         var _loc1_:IShootTargetHandler = null;
         for each(_loc1_ in this.targets)
         {
            _loc1_.targetInfo.target.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOver);
            _loc1_.targetInfo.target.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOut);
            _loc1_.dispose();
         }
         this.targets = {};
      }
      
      public function getHandler(param1:ShootInfo) : IShootTargetHandler
      {
         var _loc2_:String = param1.targetType + "_" + param1.target;
         return this.targets[_loc2_] as IShootTargetHandler;
      }
      
      public function getPlayerHandler(param1:String) : IShootTargetHandler
      {
         var _loc2_:String = ShootTargetTypes.Player + "_" + param1;
         return this.targets[_loc2_] as IShootTargetHandler;
      }
      
      private function getTargetInfoKey(param1:TargetInfo) : String
      {
         return param1.targetType + "_" + param1.targetName;
      }
      
      private function onMouseOver(param1:MouseEvent) : void
      {
         TargetIcon.instance.showActive();
      }
      
      private function onMouseOut(param1:MouseEvent) : void
      {
         TargetIcon.instance.showNormal();
      }
   }
}

