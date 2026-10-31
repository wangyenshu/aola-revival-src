package mmo.fbteam.common
{
   import flash.events.EventDispatcher;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fbteam.IFBLoaderService;
   
   public class FBCommonHelper
   {
      
      public function FBCommonHelper()
      {
         super();
      }
      
      public static function leavFBonLost() : void
      {
         var _loc1_:ModalDialog = NewDialog.getMessageDialog("挑战失败，请带上强大的亚比再来吧！");
         _loc1_.addEventListener(ModalDialogEvent.CLOSE,onOuttingClose);
         _loc1_.show();
      }
      
      private static function onOuttingClose(param1:ModalDialogEvent) : void
      {
         var _loc3_:IFBLoaderService = null;
         var _loc2_:EventDispatcher = param1.currentTarget as EventDispatcher;
         _loc2_.removeEventListener(ModalDialogEvent.CLOSE,onOuttingClose);
         if(TeamHelper.isCaptain())
         {
            _loc3_ = ServiceContainer.getService(IFBLoaderService) as IFBLoaderService;
            _loc3_.leaveFb({"force":true});
         }
      }
      
      public static function leaveFB() : void
      {
         var _loc1_:IFBLoaderService = null;
         if(TeamHelper.isCaptain())
         {
            _loc1_ = ServiceContainer.getService(IFBLoaderService) as IFBLoaderService;
            _loc1_.leaveFb({"force":true});
         }
      }
   }
}

