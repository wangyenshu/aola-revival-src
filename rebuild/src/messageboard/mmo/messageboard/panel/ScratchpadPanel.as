package mmo.messageboard.panel
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TextEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.usercard.IUserCardService;
   import mmo.messageboard.client.MessageBoardClient;
   import mmo.messageboard.data.MessageBoardData;
   
   public class ScratchpadPanel extends Sprite
   {
      
      private var data:MessageBoardData;
      
      private var userName:String;
      
      private var isMaster:Boolean;
      
      private var index:int;
      
      private var type:int;
      
      private var onClose:Function;
      
      private var sp:Sprite;
      
      private const preName:String = "mmo.messageboard.panel.Scratchpad";
      
      private var dialog:ModalDialog;
      
      private var userCardService:IUserCardService;
      
      private var isClicking:Boolean = false;
      
      public function ScratchpadPanel(param1:int, param2:int, param3:String, param4:Boolean = false, param5:Function = null)
      {
         super();
         this.type = param1;
         this.index = param2;
         this.userName = param3;
         this.isMaster = param4;
         this.onClose = param5;
         this.init();
      }
      
      private function init() : void
      {
         var cls:Class;
         ServiceContainer.instance.tryGetService(IUserCardService,function(param1:IUserCardService, param2:Object):void
         {
            userCardService = param1;
         });
         cls = ApplicationDomain.currentDomain.getDefinition(this.preName + this.type) as Class;
         this.sp = new cls() as Sprite;
         this.addChild(this.sp);
         this.sp.addEventListener(MouseEvent.CLICK,this.onClickPanel);
         if(!this.isMaster)
         {
            SimpleButton(this.sp.getChildByName("btnClose")).visible = false;
         }
         TipsManager.getInstance().addTips(InteractiveObject(this.sp.getChildByName("btn_record")),"举报");
      }
      
      public function setInfo(param1:MessageBoardData) : void
      {
         this.data = param1;
         var _loc2_:TextField = TextField(this.sp.getChildByName("txt_content"));
         _loc2_.scrollV = 0;
         _loc2_.text = this.data.content;
         var _loc3_:TextField = TextField(this.sp.getChildByName("txt_message"));
         if(param1.userName != null)
         {
            _loc3_.addEventListener(TextEvent.LINK,this.onClickLink);
            _loc3_.htmlText = "<a href=\'event:" + this.data.userName + "\'>" + this.data.nickName + "</a>" + "<br>" + this.data.month + "月" + this.data.day + "日";
         }
         else
         {
            _loc3_.htmlText = this.data.nickName + "<br>";
            this.sp.getChildByName("btn_record").visible = false;
            this.sp.getChildByName("btnClose").visible = false;
         }
      }
      
      private function onClickLink(param1:TextEvent) : void
      {
         var _loc2_:String = param1.text;
         this.userCardService.showUserCard(_loc2_);
      }
      
      private function onClickPanel(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         var _loc2_:DisplayObject = param1.target as DisplayObject;
         switch(_loc2_.name)
         {
            case "btn_record":
               if(this.data.userName == UserInfo.userName)
               {
                  NewDialog.showFailMessage("不能举报自己哦!");
                  this.isClicking = false;
                  return;
               }
               this.dialog = NewDialog.getCofirmDialog("要举报这条留言么?");
               this.dialog.addEventListener(ModalDialogEvent.OK,this.onReportOk);
               this.dialog.addEventListener(ModalDialogEvent.CANCEL,this.onClickClose);
               this.dialog.addEventListener(ModalDialogEvent.CLOSE,this.onClickClose);
               this.dialog.show();
               break;
            case "btnClose":
               if(!this.isMaster)
               {
                  NewDialog.showFailMessage("你不能删除别人的留言哦！");
                  this.isClicking = false;
                  return;
               }
               this.dialog = NewDialog.getCofirmDialog("你要删除这条留言么？删除后不能恢复哦！");
               this.dialog.addEventListener(ModalDialogEvent.OK,this.onClickOk);
               this.dialog.addEventListener(ModalDialogEvent.CANCEL,this.onClickClose);
               this.dialog.addEventListener(ModalDialogEvent.CLOSE,this.onClickClose);
               this.dialog.show();
               break;
            default:
               this.isClicking = false;
         }
      }
      
      private function onReportOk(param1:ModalDialogEvent) : void
      {
         SocketClient.instance.addEventListener(MessageBoardClient.cmdReportMsg,this.onReportMessage);
         MessageBoardClient.getInstance().reportMessage(this.userName,this.data.id);
      }
      
      private function onReportMessage(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdReportMsg,this.onReportMessage);
         if(param1.params.suc)
         {
            NewDialog.showSucceedMessage("举报成功");
         }
         else
         {
            NewDialog.showFailMessage("你已经举报过这条留言了呢！");
         }
         this.isClicking = false;
      }
      
      private function onClickOk(param1:ModalDialogEvent) : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(MessageBoardClient.cmdDelMsg,this.onDeleteMessage);
         MessageBoardClient.getInstance().deleteMessage(this.data.id);
      }
      
      private function onDeleteMessage(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(MessageBoardClient.cmdDelMsg,this.onDeleteMessage);
         if(this.onClose != null)
         {
            this.onClose.apply(null,[this.index]);
         }
         this.isClicking = false;
      }
      
      private function onClickClose(param1:ModalDialogEvent) : void
      {
         this.isClicking = false;
      }
   }
}

