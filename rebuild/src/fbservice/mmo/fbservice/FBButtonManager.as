package mmo.fbservice
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.control.IControlService;
   import mmo.interfaces.fb.IFbService;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   
   // REVIVAL: the rebuilt control bar's buttons are sprites, not SimpleButtons: kept as InteractiveObject.
   public class FBButtonManager implements IDispose
   {
      
      private static var _instance:FBButtonManager;
      
      private var control:IControlService = null;
      
      private var fbName:String = null;
      
      private var btnFBMap:InteractiveObject = null;
      
      private var btnFBLeave:InteractiveObject = null;
      
      private var btnTeam:Sprite = null;
      
      private var isDiposed:Boolean = false;
      
      public function FBButtonManager()
      {
         super();
         this.control = ServiceContainer.getService(IControlService) as IControlService;
      }
      
      public static function get instance() : FBButtonManager
      {
         if(_instance == null)
         {
            _instance = new FBButtonManager();
         }
         return _instance;
      }
      
      public function init(param1:String) : void
      {
         this.fbName = param1;
         this.control.change2fbMode();
         var _loc2_:Sprite = LayerManager.getBaseControl().getChildByName("controlBar") as Sprite;
         this.btnTeam = _loc2_.getChildByName("btnTeam") as Sprite;
         this.btnTeam.mouseEnabled = false;
         this.btnTeam.mouseChildren = false;
         var _loc3_:Array = FB_MapAndLeaveConfig.FB_MSGS[param1] as Array;
         this.btnFBMap = this.control.fbMapButton as InteractiveObject;
         this.btnFBLeave = this.control.fbLeaveButton as InteractiveObject;
         TipsManager.getInstance().addTips(this.btnFBMap,_loc3_[0]);
         TipsManager.getInstance().addTips(this.btnFBLeave,_loc3_[1]);
         this.btnFBMap.addEventListener(MouseEvent.CLICK,this.onClickMap);
         this.btnFBLeave.addEventListener(MouseEvent.CLICK,this.onClickExit);
      }
      
      public function dispose() : void
      {
         if(this.isDiposed || null == this.fbName)
         {
            return;
         }
         this.isDiposed = true;
         TipsManager.getInstance().removeTips(this.btnFBMap);
         TipsManager.getInstance().removeTips(this.btnFBLeave);
         this.btnTeam.mouseChildren = true;
         this.btnTeam.mouseEnabled = true;
         this.btnFBMap = null;
         this.btnFBLeave = null;
         this.btnTeam = null;
         this.fbName = null;
         this.control.change2commonMode();
         _instance = null;
      }
      
      private function onClickMap(param1:MouseEvent) : void
      {
         this.loadAndshowFBMap();
      }
      
      private function loadAndshowFBMap() : void
      {
         var mapInfo:Array = null;
         mapInfo = FB_MapAndLeaveConfig.FBMAP_RESINFO[this.fbName] as Array;
         if(ApplicationDomain.currentDomain.hasDefinition(mapInfo[1]))
         {
            this.showMap(mapInfo[1]);
         }
         else
         {
            ProgressFullSprite.show();
            ResScheduler.getResource(mapInfo[0],function(param1:DisplayObject):void
            {
               ProgressFullSprite.close();
               showMap(mapInfo[1]);
            });
         }
      }
      
      private function showMap(param1:String) : void
      {
         var _loc2_:Class = getDefinitionByName(param1) as Class;
         ModalDialogManager.getInstance().addModalDialog(new _loc2_());
      }
      
      private function onClickExit(param1:MouseEvent) : void
      {
         var event:MouseEvent = param1;
         var message:String = FB_MapAndLeaveConfig.FB_MSGS[this.fbName][2];
         NewDialog.getCofirmDialog(message,function(param1:ModalDialog):*
         {
            param1.addEventListener(ModalDialogEvent.OK,onConfirmExit,false,0,true);
            param1.show();
         },this,NewDialog.getSucceedIcon());
      }
      
      private function onConfirmExit(param1:ModalDialogEvent) : void
      {
         var _loc2_:IFbService = ServiceContainer.getService(IFbService) as IFbService;
         _loc2_.leaveFb({"force":true});
      }
   }
}

