package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   
   public class PetCureHandler
   {
      
      public function PetCureHandler()
      {
         super();
      }
      
      public static function tryCure() : void
      {
         var icon:DisplayObject;
         var tryHill:Function;
         var petDataService:IPetDataService = null;
         var dialog:ModalDialog = null;
         var onOk:Function = null;
         var onClose:Function = null;
         petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         if(petDataService.checkPetIsEmpty())
         {
            NewDialog.showFailMessage("你背包里没有亚比哦！");
            return;
         }
         if(Boolean(petDataService.checkAllPetHPIsFull()) && Boolean(petDataService.checkAllPetPPIsFull()))
         {
            NewDialog.showMessage("你的亚比现在都充满着活力，不需要恢复体力！");
            return;
         }
         icon = NewDialog.getSucceedIcon();
         dialog = NewDialog.getCofirmDialog("恢复亚比体力需要花费50晶币，你确定要继续吗？",null,null,icon);
         onOk = function(param1:ModalDialogEvent):void
         {
            dialog.removeEventListener(ModalDialogEvent.OK,onOk);
            dialog.removeEventListener(ModalDialogEvent.CLOSE,onClose);
            tryHill();
         };
         onClose = function(param1:ModalDialogEvent):void
         {
            dialog.removeEventListener(ModalDialogEvent.OK,onOk);
            dialog.removeEventListener(ModalDialogEvent.CLOSE,onClose);
         };
         tryHill = function():void
         {
            petDataService.recureAllPet();
         };
         if(Boolean(MemberManager.instance.isMember()) || Boolean(MemberManager.instance.isTrialMember()))
         {
            tryHill();
         }
         else
         {
            dialog.addEventListener(ModalDialogEvent.OK,onOk);
            dialog.addEventListener(ModalDialogEvent.CLOSE,onClose);
            dialog.show();
         }
      }
   }
}

