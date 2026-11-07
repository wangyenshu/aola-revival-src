package mmo.starcoinexchange.fortunemanager
{
   import mmo.revival.starcoin.Beans;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManager;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManagerClient;
   import mmo.starcoinexchange.interfaces.IInitPanel;
   
   public class FortunemanagerPanel extends Sprite implements IInitPanel
   {
      
      public var advanceGetBackCoin:AdvanceGetBackPanel;
      
      public var beSurePanel:SurePanel;
      
      public var getBackCoin:ReturnCoinPanel;
      
      public var oneDayGetBack:OneDayGetBackPanel;
      
      public var storeCoin:StoreCoinPanel;
      
      public var storeMessage:StoreMessagePanel;
      
      private var storeMessagePanel:Sprite;
      
      private var storeCoinPanel:Sprite;
      
      private var surePanel:Sprite;
      
      private var returnCoinPanel:Sprite;
      
      private var advanceGetBackPanel:Sprite;
      
      private var oneDayGetBackPanel:Sprite;
      
      private var iconExchangePanel:Sprite;
      
      private var panelArray:Array;
      
      private var isActivityDay:Boolean;
      
      private var _mcActivityPanel:MovieClip;
      
      public function FortunemanagerPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this.storeMessagePanel = Sprite(this.storeMessage);
         this.storeCoinPanel = Sprite(this.storeCoin);
         this.surePanel = Sprite(this.beSurePanel);
         this.returnCoinPanel = Sprite(this.getBackCoin);
         this.advanceGetBackPanel = Sprite(this.advanceGetBackCoin);
         this.oneDayGetBackPanel = Sprite(this.oneDayGetBack);
         this.panelArray = [this.storeMessagePanel,this.storeCoinPanel,this.surePanel,this.returnCoinPanel,this.advanceGetBackPanel,this.oneDayGetBackPanel];
         this.initVisible();
         FortuneManagerEventDispatcher.getInstance().addEventListener(FortuneManagerEvent.SHOW_PANEL,this.onShowPanel);
         SocketClient.instance.addEventListener(FortuneManagerClient.cmdGetAccount,this.onGetAccount);
         FortuneManagerClient.getInstance().getStoreMessage();
      }
      
      public function initPanel() : void
      {
      }
      
      private function initVisible() : void
      {
         this.storeMessagePanel.visible = true;
         this.storeCoinPanel.visible = false;
         this.surePanel.visible = false;
         this.returnCoinPanel.visible = false;
         this.advanceGetBackPanel.visible = false;
         this.oneDayGetBackPanel.visible = false;
      }
      
      private function onGetAccount(param1:SocketClientEvent) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Date = null;
         var _loc7_:int = 0;
         FortuneManager.getInstance().clearFortuneArr();
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdGetAccount,this.onGetAccount);
         Beans.update(param1.params);
         var _loc2_:Array = param1.params.al;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = int(_loc2_[_loc3_].id);
            _loc5_ = int(_loc2_[_loc3_].sc);
            _loc6_ = new Date(_loc2_[_loc3_].sd);
            _loc7_ = int(_loc2_[_loc3_].d);
            FortuneManager.getInstance().storeFortuneOfMes(_loc4_,_loc5_,_loc6_,_loc7_);
            _loc3_++;
         }
         (this.storeMessagePanel as IFortuneManagerPanel).initPanel(null);
      }
      
      private function onShowPanel(param1:FortuneManagerEvent) : void
      {
         var _loc2_:int = int(param1.params.panelId);
         if(_loc2_ == -1)
         {
            this.dispose();
            return;
         }
         this.showPanel(_loc2_,param1.params);
      }
      
      private function showPanel(param1:int, param2:Object) : void
      {
         var _loc4_:IFortuneManagerPanel = null;
         var _loc3_:int = 0;
         while(_loc3_ < this.panelArray.length)
         {
            if(_loc3_ == param1)
            {
               _loc4_ = this.panelArray[_loc3_] as IFortuneManagerPanel;
               _loc4_.initPanel(param2);
               Sprite(this.panelArray[_loc3_]).visible = true;
            }
            else
            {
               Sprite(this.panelArray[_loc3_]).visible = false;
            }
            _loc3_++;
         }
      }
      
      private function dispose() : void
      {
         FortuneManagerEventDispatcher.getInstance().removeEventListener(FortuneManagerEvent.SHOW_PANEL,this.onShowPanel);
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdGetAccount,this.onGetAccount);
      }
   }
}

