package mmo.activity130131.qiling
{
   import flash.display.DisplayObject;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.dialog.SpecialMessageDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.data.IPetDataService;
   
   public class QilingUtil
   {
      
      public function QilingUtil()
      {
         super();
      }
      
      public static function tryCure() : void
      {
         var tryHill:Function;
         var icon:DisplayObject;
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
         tryHill = function():void
         {
            petDataService.recureAllPet();
         };
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
      
      public static function buy(param1:int, param2:int, param3:Function = null, param4:Boolean = false) : void
      {
         var itemId:int = param1;
         var quantity:int = param2;
         var callBack:Function = param3;
         var ed:Boolean = param4;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(MaterialClient.cmdBuyMaterial,function onBuyEnd(param1:SocketClientEvent):void
         {
            ProgressFullSprite.close();
            SocketClient.instance.removeEventListener(MaterialClient.cmdBuyMaterial,onBuyEnd);
            switch(param1.params.result)
            {
               case 1:
                  if(callBack != null)
                  {
                     callBack.apply();
                  }
                  break;
               case 101:
                  SpecialMessageDialog.showSpecialMessageDialog("XingbeShortageHandler","很抱歉，你的星币余额不足，目前你拥有" + UserInfo.xingbi + "星币。");
                  break;
               case 3:
                  NewDialog.showFailMessage("你不能拥有更多的该物品。");
                  break;
               case 12:
                  NewDialog.showFailMessage("已经到达当天消费上限，请明天再来吧!");
                  break;
               case 13:
                  NewDialog.showFailMessage("已经到达当月消费上限。");
                  break;
               default:
                  NewDialog.showFailMessage("购买失败，请联系客服。" + param1.params.result);
            }
         });
         MaterialClient.getInstance().buyMaterial(MaterialTypes.ITEM,itemId,quantity,ed);
      }
   }
}

