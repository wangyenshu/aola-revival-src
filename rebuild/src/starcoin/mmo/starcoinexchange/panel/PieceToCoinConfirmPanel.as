package mmo.starcoinexchange.panel
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.navigate.INavigateService;
   import mmo.starcoinexchange.client.StarCoinClient;
   import mmo.starcoinexchange.config.StarCoinConfig;
   
   public class PieceToCoinConfirmPanel extends Sprite implements IShowPanel, IDispose
   {
      
      public var btnBlue:SimpleButton;
      
      public var btnClose:SimpleButton;
      
      public var btnOk:SimpleButton;
      
      public var mcTips:MovieClip;
      
      public var txtCoinNum:TextField;
      
      public var txtNeed:TextField;
      
      private var coinNum:int;
      
      private var onClose:Function;
      
      private var thisObj:*;
      
      public function PieceToCoinConfirmPanel(param1:int, param2:Function, param3:* = null)
      {
         super();
         this.coinNum = param1;
         this.onClose = param2;
         this.thisObj = param3;
         this.init();
      }
      
      private function init() : void
      {
         DisplayObject(this.btnBlue).visible = !MemberManager.instance.isMember();
         MovieClip(this.mcTips).gotoAndStop(MemberManager.instance.isMember() ? 2 : 1);
         var _loc1_:int = MemberManager.instance.isMember() ? int(StarCoinConfig.PIECE_TO_COIN_RAIE_VIP * this.coinNum) : int(StarCoinConfig.PIECE_TO_COIN_RATE * this.coinNum);
         TextField(this.txtNeed).text = _loc1_.toString();
         TextField(this.txtCoinNum).text = this.coinNum.toString();
         var _loc2_:int = (StarCoinConfig.PIECE_TO_COIN_RATE - StarCoinConfig.PIECE_TO_COIN_RAIE_VIP) * this.coinNum;
         TextField(this.mcTips.txtSaveNum).text = _loc2_.toString();
         this.addEventListener(MouseEvent.CLICK,this.onClickPanel);
      }
      
      private function onClickPanel(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         var targetName:String = evt.target.name;
         if(targetName == "btnOk")
         {
            this.exchangeCoin();
         }
         else if(targetName == "btnClose")
         {
            this.closePanel(false);
         }
         else if(targetName == "btnBlue")
         {
            ProgressFullSprite.show();
            ServiceContainer.instance.tryGetService(INavigateService,function(param1:INavigateService, param2:Object):void
            {
               ProgressFullSprite.close();
               param1.goToBlueDiamond();
            });
         }
      }
      
      private function exchangeCoin() : void
      {
         this.exchange();
      }
      
      private function exchange() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(StarCoinClient.cmdExchangeStarCoin,this.onExchange);
         StarCoinClient.instance.exchangeStarCoin(this.coinNum);
      }
      
      private function onExchange(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(StarCoinClient.cmdExchangeStarCoin,this.onExchange);
         var _loc2_:int = int(param1.params.result);
         if(_loc2_ == 1)
         {
            NewDialog.showSucceedMessage("成功铸造了" + this.coinNum.toString() + "星币");
            this.closePanel(true);
         }
         else if(_loc2_ == 2)
         {
            NewDialog.showFailMessage("你今天已经铸造了很多星币咯，请明天再来吧。");
         }
         else if(_loc2_ == 3)
         {
            NewDialog.showFailMessage("你本月已经铸造了很多星币咯，请下个月再来吧。");
         }
         else if(_loc2_ == 6)
         {
            NewDialog.showFailMessage("你的流星碎片不够哦");
         }
         else
         {
            NewDialog.showFailMessage("铸造失败～");
         }
      }
      
      private function closePanel(param1:Boolean) : void
      {
         this.onClose.apply(this.thisObj,[param1]);
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function showPanel() : void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClickPanel);
      }
   }
}

