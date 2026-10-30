package mmo.shoot.shootbar
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class ShootButtonWrap extends Sprite implements IDispose
   {
      
      public var mcShoot:MovieClip;
      
      public var pnlShoot:ShootPanel;
      
      private var shootPanel:ShootPanel;
      
      private var _userIsInHotSpring:Boolean;
      
      private var _controlBarSkinService:NoSkins = NoSkins.instance;
      
      public function ShootButtonWrap()
      {
         super();
         this.shootPanel = this.getChildByName("pnlShoot") as ShootPanel;
         this.removeChild(this.shootPanel);
         ActComHelper.setMcFrame(this,"mcShoot",this._controlBarSkinService.getUsingSkinId() + 1);
         var _loc1_:SimpleButton = ActComHelper.getChildNode(this,"mcShoot.btnShoot") as SimpleButton;
         TipsManager.getInstance().addTips(_loc1_,"射击",0,0,-20);
         _loc1_.addEventListener(MouseEvent.CLICK,this.btnShootClick);
         CommonEventDispatcher.instance.addEventListener("commonevnt_userouthotspring",this.onUserOutSpring);
         CommonEventDispatcher.instance.addEventListener("commonevnt_userinhotspring",this.onUserInSpring);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         CommonEventDispatcher.instance.addEventListener(NoSkins.CHANGE,this.onChangeSkin);
      }
      
      private function onChangeSkin(param1:CommonEvent) : void
      {
         var _loc2_:SimpleButton = ActComHelper.getChildNode(this,"mcShoot.btnShoot") as SimpleButton;
         _loc2_.removeEventListener(MouseEvent.CLICK,this.btnShootClick);
         ActComHelper.setMcFrame(this,"mcShoot",this._controlBarSkinService.getUsingSkinId() + 1);
         _loc2_ = ActComHelper.getChildNode(this,"mcShoot.btnShoot") as SimpleButton;
         TipsManager.getInstance().addTips(_loc2_,"射击",0,0,-20);
         _loc2_.addEventListener(MouseEvent.CLICK,this.btnShootClick);
      }
      
      private function onUserInSpring(param1:CommonEvent) : void
      {
         this._userIsInHotSpring = true;
         if(this.shootPanel.parent != null)
         {
            this.removeChild(this.shootPanel);
         }
      }
      
      private function onUserOutSpring(param1:CommonEvent) : void
      {
         this._userIsInHotSpring = false;
      }
      
      private function onAddToStage(param1:Event) : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         this.stage.addEventListener(MouseEvent.MOUSE_MOVE,this.onStageMouseMove);
      }
      
      private function btnShootClick(param1:MouseEvent) : void
      {
         if(this._userIsInHotSpring)
         {
            NewDialog.showFailMessage("欢乐岛内不能射击哟！");
            return;
         }
         if(this.shootPanel.parent != null)
         {
            this.hidePanel();
            return;
         }
         this.shootPanel.show();
         this.addChild(this.shootPanel);
         CommonEventDispatcher.instance.dispatchEvent(new Event("clickShootBtn"));
      }
      
      /** REBUILT: open or close the card panel from the 2013 control bar's own 射击 button. */
      public function toggle() : void
      {
         this.btnShootClick(null);
      }

      private function hidePanel() : void
      {
         if(this.shootPanel.parent != null)
         {
            if(this.shootPanel.isLock())
            {
               return;
            }
            this.removeChild(this.shootPanel);
            CommonEventDispatcher.instance.dispatchEvent(new Event("closeShootBtn"));
            return;
         }
      }
      
      private function onStageMouseMove(param1:MouseEvent) : void
      {
         if(this.shootPanel.parent == null)
         {
            return;
         }
         if(!this.hitTestPoint(param1.stageX,param1.stageY,true))
         {
            this.hidePanel();
         }
      }
      
      public function dispose() : void
      {
         this.stage.removeEventListener(MouseEvent.MOUSE_MOVE,this.onStageMouseMove);
         CommonEventDispatcher.instance.removeEventListener(NoSkins.CHANGE,this.onChangeSkin);
         this.shootPanel.dispose();
         this.shootPanel = null;
      }
   }
}

