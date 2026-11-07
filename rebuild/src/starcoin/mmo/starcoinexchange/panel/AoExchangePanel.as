package mmo.starcoinexchange.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.Commands;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.LoaderContainer;
   import mmo.starcoinexchange.client.StarCoinClient;
   import mmo.starcoinexchange.config.StarCoinConfig;
   import mmo.starcoinexchange.interfaces.IInitPanel;
   
   public class AoExchangePanel extends MovieClip implements IDispose, IInitPanel
   {
      
      private static const EXCHANGE_CANNOT_TIP:String = "请选择你要铸造的数量";
      
      public var btnAdd:SimpleButton;
      
      public var btnChargeAoCoin:SimpleButton;
      
      public var btnExchange:SimpleButton;
      
      public var btnSub:SimpleButton;
      
      public var tipsLeft:MovieClip;
      
      public var tipsRight:MovieClip;
      
      public var txtAo:TextField;
      
      public var txtAoHave:TextField;
      
      public var txtStar:TextField;
      
      public var txtStarHave:TextField;
      
      private var ao:int = 0;
      
      private var Star:int = 0;
      
      private var aoHave:Number = 0;
      
      public function AoExchangePanel()
      {
         super();
         SocketClient.instance.addEventListener(StarCoinClient.cmdGetAo,this.onGetAo);
         StarCoinClient.instance.getAo();
      }
      
      public function initPanel() : void
      {
         SocketClient.instance.addEventListener(Commands.onXingBiUpdated,this.onXingbiUpdate);
         SimpleButton(this.btnSub).addEventListener(MouseEvent.CLICK,this.onClickSub);
         SimpleButton(this.btnAdd).addEventListener(MouseEvent.CLICK,this.onClickAdd);
         SimpleButton(this.btnExchange).addEventListener(MouseEvent.CLICK,this.onClickExchange);
         TipsManager.getInstance().addTips(this.tipsLeft,"已经是0了，不能再少啦");
         TipsManager.getInstance().addTips(this.tipsRight,"不能再多啦，你身上没有这么多奥币哦");
         this.ao = 0;
         this.Star = 0;
         TextField(this.txtAo).text = this.ao.toString();
         TextField(this.txtAo).restrict = "0-9";
         TextField(this.txtAo).addEventListener(Event.CHANGE,this.onChange);
         TextField(this.txtStar).text = this.Star.toString();
         TextField(this.txtStarHave).text = UserInfo.xingbi.toString();
         this.enAbleExchange();
         this.forbidButton(this.btnSub);
         this.initAoHaveTxt();
         this.initBtnTips();
      }
      
      private function onXingbiUpdate(param1:SocketClientEvent) : void
      {
         TextField(this.txtStarHave).text = UserInfo.xingbi.toString();
         SocketClient.instance.addEventListener(StarCoinClient.cmdGetAo,this.onGetAo);
         StarCoinClient.instance.getAo();
      }
      
      private function onChange(param1:Event) : void
      {
         var _loc2_:int = int(param1.currentTarget.text);
         if(_loc2_ < 0)
         {
            _loc2_ = 0;
         }
         else if(_loc2_ > this.aoHave)
         {
            _loc2_ = this.aoHave;
         }
         this.ao = _loc2_;
         this.Star = this.ao * StarCoinConfig.AO_TO_COIN_RATE;
         if(this.ao < int(this.aoHave))
         {
            this.ableButton(this.btnAdd);
         }
         if(this.ao <= 0)
         {
            this.forbidButton(this.btnSub);
         }
         if(this.ao > 0)
         {
            this.ableButton(this.btnSub);
         }
         if(this.ao >= int(this.aoHave))
         {
            this.forbidButton(this.btnAdd);
         }
         if(this.ao <= 0)
         {
            this.enAbleExchange();
         }
         else
         {
            this.ableExchange();
         }
         TextField(this.txtAo).text = this.ao.toString();
         TextField(this.txtStar).text = this.Star.toString();
      }
      
      private function onClickTab(param1:MouseEvent) : void
      {
         this.parent.removeChild(this);
      }
      
      private function onGetAo(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(StarCoinClient.cmdGetAo,this.onGetAo);
         this.aoHave = param1.params.aobi;
         TextField(this.txtAoHave).text = this.aoHave.toFixed(2);
         if(int(this.aoHave) == 0)
         {
            this.forbidButton(this.btnAdd);
         }
         this.initAoHaveTxt();
         this.initBtnTips();
      }
      
      private function initAoHaveTxt() : void
      {
         if(int(this.aoHave) == 0)
         {
            TextField(this.txtAo).selectable = false;
            TextField(this.txtAo).type = TextFieldType.DYNAMIC;
            TipsManager.getInstance().addTips(this.txtAo,"你目前还没有奥币哦，请先充值吧");
         }
         else
         {
            TextField(this.txtAo).selectable = true;
            TextField(this.txtAo).type = TextFieldType.INPUT;
            TipsManager.getInstance().removeTips(this.txtAo);
         }
      }
      
      private function initBtnTips() : void
      {
         if(int(this.aoHave) == 0)
         {
            TipsManager.getInstance().removeTips(this.tipsLeft);
            TipsManager.getInstance().removeTips(this.tipsRight);
            TipsManager.getInstance().addTips(this.tipsLeft,"你目前还没有奥币哦，请先充值吧");
            TipsManager.getInstance().addTips(this.tipsRight,"你目前还没有奥币哦，请先充值吧");
         }
         else
         {
            TipsManager.getInstance().removeTips(this.tipsLeft);
            TipsManager.getInstance().removeTips(this.tipsRight);
            TipsManager.getInstance().addTips(this.tipsLeft,"已经是0了，不能再少啦");
            TipsManager.getInstance().addTips(this.tipsRight,"不能再多啦，你身上没有这么多奥币哦");
         }
      }
      
      private function onClickSub(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.currentTarget as SimpleButton;
         if(!_loc2_.enabled)
         {
            return;
         }
         if(int(this.aoHave) == this.ao)
         {
            this.ableButton(this.btnAdd);
         }
         --this.ao;
         this.Star -= StarCoinConfig.AO_TO_COIN_RATE;
         if(this.ao == 0)
         {
            this.ao = 0;
            this.Star = 0;
            this.enAbleExchange();
            this.forbidButton(this.btnSub);
         }
         TextField(this.txtAo).text = this.ao.toString();
         TextField(this.txtStar).text = this.Star.toString();
      }
      
      private function onClickAdd(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.currentTarget as SimpleButton;
         if(!_loc2_.enabled)
         {
            return;
         }
         if(this.ao == 0 && this.ao < int(this.aoHave))
         {
            this.ableButton(this.btnSub);
            this.ableExchange();
         }
         if(this.ao < int(this.aoHave))
         {
            ++this.ao;
            this.Star += StarCoinConfig.AO_TO_COIN_RATE;
            TextField(this.txtAo).text = this.ao.toString();
            TextField(this.txtStar).text = this.Star.toString();
            if(this.ao == int(this.aoHave))
            {
               this.forbidButton(this.btnAdd);
            }
         }
      }
      
      private function enAbleExchange() : void
      {
         DisplayUtil.applyGray(this.btnExchange);
         SimpleButton(this.btnExchange).enabled = false;
         TipsManager.getInstance().addTips(this.btnExchange,EXCHANGE_CANNOT_TIP);
      }
      
      private function ableExchange() : void
      {
         DisplayUtil.clearFilters(this.btnExchange);
         SimpleButton(this.btnExchange).enabled = true;
         TipsManager.getInstance().removeTips(this.btnExchange);
      }
      
      private function onClickExchange(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.currentTarget as SimpleButton;
         if(!_loc2_.enabled)
         {
            return;
         }
         LoaderContainer.instance.stage.focus = null;
         this.afterVertifyExchange();
      }
      
      private function afterVertifyExchange() : void
      {
         this.enAbleExchange();
         SocketClient.instance.addEventListener(StarCoinClient.cmdAoToStarCoin,this.onExchangeResult);
         StarCoinClient.instance.aoToStarCoin(this.ao);
      }
      
      private function onExchangeResult(param1:SocketClientEvent) : void
      {
         var res:int;
         var addXingbe:int = 0;
         var onMDClose:Function = null;
         var md:ModalDialog = null;
         var e:SocketClientEvent = param1;
         this.ableExchange();
         SocketClient.instance.removeEventListener(StarCoinClient.cmdAoToStarCoin,this.onExchangeResult);
         res = int(e.params.res);
         switch(res)
         {
            case 1:
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("ExchangeCoin",{"coinNum":this.ao * StarCoinConfig.AO_TO_COIN_RATE}));
               addXingbe = this.ao * StarCoinConfig.AO_TO_COIN_RATE;
               onMDClose = function(param1:ModalDialogEvent):void
               {
                  EventDispatcher(e.currentTarget).removeEventListener(ModalDialogEvent.CLOSE,onMDClose);
               };
               md = NewDialog.getDialog("成功铸造了" + addXingbe + "个星币",NewDialog.getSucceedIcon());
               md.addEventListener(ModalDialogEvent.CLOSE,onMDClose);
               md.show();
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("_AO_Exchange_Coin_",{}));
               this.aoHave -= this.ao;
               TextField(this.txtAoHave).text = this.aoHave.toFixed(2);
               this.ao = 0;
               this.Star = 0;
               TextField(this.txtAo).text = this.ao.toString();
               TextField(this.txtStar).text = this.Star.toString();
               TextField(this.txtStarHave).text = UserInfo.xingbi.toString();
               this.enAbleExchange();
               this.forbidButton(this.btnSub);
               if(this.aoHave == 0)
               {
                  this.forbidButton(this.btnAdd);
               }
               this.initAoHaveTxt();
               this.initBtnTips();
               break;
            case 2:
               NewDialog.showSucceedMessage("铸造失败");
               break;
            case 3:
               NewDialog.showFailMessage("你拥有的奥币不足哦，请积累更多的奥币再来铸造吧！");
               break;
            case 4:
               NewDialog.showFailMessage("你当日铸造的星币已经达到上限，请明天再来吧！");
               break;
            case 5:
               NewDialog.showFailMessage("你当月铸造的星币已经达到上限，请下个月再来吧！");
               break;
            default:
               NewDialog.showSucceedMessage("铸造失败");
         }
      }
      
      private function forbidButton(param1:SimpleButton, param2:String = null) : void
      {
         DisplayUtil.applyGray(param1);
         SimpleButton(param1).mouseEnabled = false;
         if(param2 != null)
         {
            TipsManager.getInstance().addTips(param1,param2);
         }
      }
      
      private function ableButton(param1:SimpleButton) : void
      {
         DisplayUtil.clearFilters(param1);
         SimpleButton(param1).mouseEnabled = true;
         TipsManager.getInstance().removeTips(param1);
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(Commands.onXingBiUpdated,this.onXingbiUpdate);
      }
   }
}

