package mmo.starcoinexchange.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.AlignType;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.IShowPanel;
   import mmo.play.activity.framework.util.LinkUtil;
   import mmo.starcoinexchange.fortunemanager.FortunemanagerPanel;
   import mmo.starcoinexchange.interfaces.IInitPanel;
   
   public class ExchangePanel extends Sprite implements IShowPanel, IShowDataPanel
   {
      
      private static const PRE_TAB:String = "tab";
      
      private static const CHANGE_PRE_COIN:int = 30;
      
      public var aoexchange:AoExchangePanel;
      
      public var btnClose:SimpleButton;
      
      public var fortunemanage:FortunemanagerPanel;
      
      public var tab0:MovieClip;
      
      public var tab1:MovieClip;
      
      public var tab2:MovieClip;
      
      public var xingexchange:PieceExchangePanel;
      
      private var aoExchangePanel:Sprite;
      
      private var xingExchangePanel:Sprite;
      
      private var fortuneManagePanel:Sprite;
      
      private var tabPanels:Array = [];
      
      private var curTab:int = -1;
      
      private var isActivityDay:Boolean;
      
      private var _mcActivityPanel:MovieClip;
      
      private var aoExchangeBtnPoint:Point = new Point(-142.8,126.6);
      
      private var pieceExchangeBtnPoint:Point = new Point(-142.8,126.4);
      
      private var isGainAll:Boolean = false;
      
      private var _isGotGift:Boolean;
      
      private var btn_LiuXingFuLi:SimpleButton;
      
      public function ExchangePanel(param1:Boolean = false)
      {
         super();
         this.initVals();
         this.initLinstener();
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("StarCoinPanelOpen",{}));
      }
      
      private function onLoadComplete(param1:IShowPanel, param2:ApplicationDomain) : void
      {
         param1.showPanel();
      }
      
      private function initVals() : void
      {
         this.aoExchangePanel = Sprite(this.aoexchange);
         IInitPanel(this.aoExchangePanel).initPanel();
         this.xingExchangePanel = Sprite(this.xingexchange);
         this.fortuneManagePanel = Sprite(this.fortunemanage);
         this.tabPanels = [this.aoExchangePanel,this.xingExchangePanel,this.fortuneManagePanel];
         this.setTab(0);
      }
      
      private function initLinstener() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.tabPanels.length)
         {
            _loc2_ = getChildByName(PRE_TAB + _loc1_) as MovieClip;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickTab);
            _loc1_++;
         }
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         this.addEventListener(MouseEvent.CLICK,this.onClickPanel);
      }
      
      private function onClickPanel(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnLanBaoShi")
         {
            this.openLanBaoShi();
         }
         else if(_loc2_ == "btnChargeAoCoin")
         {
            this.chargeAoCoin();
         }
      }
      
      private function onClickTab(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         var _loc3_:int = parseInt(_loc2_.name.substr(PRE_TAB.length));
         this.setTab(_loc3_);
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("StarCoinPanelClickClose",{}));
         this.close();
      }
      
      private function setTab(param1:int) : void
      {
         this.curTab = param1;
         this.refreshTab();
      }
      
      private function refreshTab() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:Sprite = null;
         var _loc4_:int = 0;
         var _loc1_:int = 0;
         while(_loc1_ < this.tabPanels.length)
         {
            _loc2_ = getChildByName(PRE_TAB + _loc1_) as MovieClip;
            _loc3_ = this.tabPanels[_loc1_] as Sprite;
            IInitPanel(_loc3_).initPanel();
            _loc3_.visible = _loc1_ == this.curTab;
            _loc4_ = _loc1_ == this.curTab ? 1 : 2;
            _loc2_.gotoAndStop(_loc4_);
            _loc1_++;
         }
      }
      
      private function openLanBaoShi() : void
      {
         LinkUtil.goToBlueDiamond();
      }
      
      private function chargeAoCoin() : void
      {
         NewDialog.showFailMessage("奥币可以在工具箱里得到哦！");
      }
      
      public function showPanel() : void
      {
         this.show();
      }
      
      public function showPanelByData(param1:Object) : void
      {
         this.setTab(param1.tabIndex);
         this.showPanel();
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function show() : void
      {
         ModalDialogManager.getInstance().addModalDialog(this,AlignType.MIDDLE_CENTER,PanelEffect.NONE,true,0,0,true);
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.tabPanels.length)
         {
            if(this.tabPanels[_loc1_] is IDispose)
            {
               IDispose(this.tabPanels[_loc1_]).dispose();
            }
            _loc1_++;
         }
      }
   }
}

