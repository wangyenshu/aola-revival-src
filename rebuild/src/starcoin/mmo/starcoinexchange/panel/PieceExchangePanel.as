package mmo.starcoinexchange.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.Commands;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.starcoinexchange.config.StarCoinConfig;
   import mmo.starcoinexchange.interfaces.IInitPanel;
   
   public class PieceExchangePanel extends MovieClip implements IDispose, IInitPanel
   {
      
      private static const EXCHANGE_CANNOT_TIP:String = "请选择你要铸造的数量";
      
      public var btnExchange:SimpleButton;
      
      public var btnL:SimpleButton;
      
      public var btnLanBaoShi:SimpleButton;
      
      public var btnR:SimpleButton;
      
      public var coin:MovieClip;
      
      public var needPiece:TextField;
      
      public var ownCoin:TextField;
      
      public var ownPiece:TextField;
      
      public var piece:MovieClip;
      
      public var tipsLeft:MovieClip;
      
      public var tipsRight:MovieClip;
      
      public var wantCoin:TextField;
      
      private var needPieceNum:int = 0;
      
      private var wantCoinNum:int = 0;
      
      private var ownPieceNum:int;
      
      private var ownCoinNum:int;
      
      private var coinRaie:int = 1;
      
      public function PieceExchangePanel()
      {
         super();
         if(MemberManager.instance.isMember())
         {
            this.coinRaie = StarCoinConfig.PIECE_TO_COIN_RAIE_VIP;
         }
         else
         {
            this.coinRaie = StarCoinConfig.PIECE_TO_COIN_RATE;
         }
      }
      
      public function initPanel() : void
      {
         this.initVals();
         SocketClient.instance.addEventListener(Commands.onXingBiUpdated,this.onXingbiUpdate);
         this.disableBtn(this.btnL,this.onClickLeft);
         this.disableBtn(this.btnExchange,this.onClickExchange,EXCHANGE_CANNOT_TIP);
         TextField(this.needPiece).text = "";
         TextField(this.wantCoin).text = "0";
         TextField(this.wantCoin).restrict = "0-9";
         TextField(this.wantCoin).addEventListener(Event.CHANGE,this.txtChange);
         var _loc1_:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var _loc2_:UserItem = _loc1_.getMyItemById(162);
         if(_loc2_ == null || _loc2_.quantity <= 0)
         {
            this.ownPieceNum = 0;
         }
         else
         {
            this.ownPieceNum = _loc2_.quantity;
         }
         if(this.ownPieceNum >= this.coinRaie)
         {
            this.enableBtn(this.btnR,this.onClickRight);
         }
         else
         {
            this.disableBtn(this.btnR,this.onClickRight);
         }
         this.ownCoinNum = UserInfo.xingbi;
         this.updateNum();
         TipsManager.getInstance().addTips(this.piece,"流星碎片");
         TipsManager.getInstance().addTips(this.coin,"星币");
      }
      
      private function txtChange(param1:Event) : void
      {
         var _loc2_:int = parseInt(TextField(this.wantCoin).text);
         var _loc3_:int = int(this.ownPieceNum / this.coinRaie);
         if(_loc2_ > _loc3_)
         {
            this.wantCoinNum = _loc3_;
         }
         else
         {
            this.wantCoinNum = _loc2_;
         }
         if(this.wantCoinNum == 0)
         {
            this.disableBtn(this.btnExchange,this.onClickExchange,EXCHANGE_CANNOT_TIP);
         }
         else
         {
            this.enableBtn(this.btnExchange,this.onClickExchange);
         }
         this.countExchange();
         this.updateNum();
         if(this.wantCoinNum == 0)
         {
            this.disableBtn(this.btnL,this.onClickLeft);
         }
         else
         {
            this.enableBtn(this.btnL,this.onClickLeft);
         }
         if(this.wantCoinNum == _loc3_)
         {
            this.disableBtn(this.btnR,this.onClickRight);
         }
         else
         {
            this.enableBtn(this.btnR,this.onClickRight);
         }
      }
      
      public function initVals() : void
      {
         this.needPieceNum = 0;
         this.wantCoinNum = 0;
      }
      
      private function onXingbiUpdate(param1:SocketClientEvent) : void
      {
         this.ownCoinNum = UserInfo.xingbi;
         TextField(this.ownCoin).text = this.ownCoinNum.toString();
      }
      
      private function onClickTab(param1:MouseEvent) : void
      {
         this.dispose();
         this.parent.removeChild(this);
      }
      
      private function onClickExchange(param1:MouseEvent) : void
      {
         new PieceToCoinConfirmPanel(this.wantCoinNum,this.onCloseConfirmPanel,this).showPanel();
      }
      
      private function onCloseConfirmPanel(param1:Boolean) : void
      {
         if(param1)
         {
            this.ownPieceNum -= this.needPieceNum;
            this.needPieceNum = 0;
            this.wantCoinNum = 0;
            this.disableBtn(this.btnL,this.onClickLeft);
            this.disableBtn(this.btnExchange,this.onClickExchange,EXCHANGE_CANNOT_TIP);
            if(this.ownPieceNum >= this.coinRaie)
            {
               this.enableBtn(this.btnR,this.onClickRight);
            }
            else
            {
               this.disableBtn(this.btnR,this.onClickRight);
            }
            this.updateNum();
         }
      }
      
      private function onClickLeft(param1:MouseEvent) : void
      {
         --this.wantCoinNum;
         this.countExchange();
         this.updateNum();
         if(this.wantCoinNum <= 0)
         {
            this.disableBtn(this.btnL,this.onClickLeft);
            this.disableBtn(this.btnExchange,this.onClickExchange,EXCHANGE_CANNOT_TIP);
         }
         this.enableBtn(this.btnR,this.onClickRight);
      }
      
      private function onClickRight(param1:MouseEvent) : void
      {
         ++this.wantCoinNum;
         if(this.wantCoinNum == 1)
         {
            this.enableBtn(this.btnExchange,this.onClickExchange);
         }
         this.countExchange();
         this.updateNum();
         var _loc2_:int = int(this.ownPieceNum / this.coinRaie);
         if(this.wantCoinNum >= _loc2_)
         {
            this.disableBtn(this.btnR,this.onClickRight);
         }
         this.enableBtn(this.btnL,this.onClickLeft);
      }
      
      private function enableBtn(param1:SimpleButton, param2:Function) : *
      {
         DisplayUtil.clearFilters(param1);
         param1.enabled = true;
         param1.addEventListener(MouseEvent.CLICK,param2);
         TipsManager.getInstance().removeTips(param1);
      }
      
      private function disableBtn(param1:SimpleButton, param2:Function, param3:String = null) : *
      {
         DisplayUtil.applyGray(param1);
         param1.enabled = false;
         param1.removeEventListener(MouseEvent.CLICK,param2);
         if(param3 != null)
         {
            TipsManager.getInstance().addTips(param1,param3);
         }
      }
      
      private function countExchange() : void
      {
         this.needPieceNum = this.wantCoinNum * this.coinRaie;
      }
      
      private function updateNum() : void
      {
         if(this.needPieceNum <= 0)
         {
            TextField(this.needPiece).text = "0";
         }
         else
         {
            TextField(this.needPiece).text = this.needPieceNum.toString();
         }
         TextField(this.wantCoin).text = this.wantCoinNum.toString();
         TextField(this.ownPiece).text = this.ownPieceNum.toString();
         TextField(this.ownCoin).text = this.ownCoinNum.toString();
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(Commands.onXingBiUpdated,this.onXingbiUpdate);
         TextField(this.wantCoin).removeEventListener(Event.CHANGE,this.txtChange);
      }
   }
}

