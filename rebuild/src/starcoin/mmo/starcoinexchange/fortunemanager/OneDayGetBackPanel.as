package mmo.starcoinexchange.fortunemanager
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.revival.starcoin.Beans;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManager;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManagerClient;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   
   public class OneDayGetBackPanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var btnReturn:SimpleButton;
      
      public var btnSure:SimpleButton;
      
      private var storeId:int;
      
      private var money:int;
      
      private var isClicking:Boolean = false;
      
      public function OneDayGetBackPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         SimpleButton(this.btnSure).addEventListener(MouseEvent.CLICK,this.onClickSure);
         SimpleButton(this.btnReturn).addEventListener(MouseEvent.CLICK,this.onClickReturn);
      }
      
      private function onClickSure(param1:MouseEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         SocketClient.instance.addEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayAccount);
         FortuneManagerClient.getInstance().takeAwayAccount(this.storeId);
      }
      
      private function onTakeAwayAccount(param1:SocketClientEvent) : void
      {
         this.isClicking = false;
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayAccount);
         var _loc2_:int = int(param1.params.res);
         Beans.update(param1.params);
         if(_loc2_ != -1)
         {
            Beans.got(this.money + _loc2_);
            FortuneManager.getInstance().returnMyStore(this.storeId);
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
         }
      }
      
      private function onClickReturn(param1:MouseEvent) : void
      {
         FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
      }
      
      public function initPanel(param1:Object) : void
      {
         this.storeId = param1.id;
         this.money = param1.money;
      }
   }
}

