package mmo.starcoinexchange.fortunemanager
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.revival.starcoin.Beans;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManager;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManagerClient;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   
   public class AdvanceGetBackPanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var accrual:TextField;
      
      public var btnReturn:SimpleButton;
      
      public var btnSure:SimpleButton;
      
      public var day:TextField;
      
      public var money:TextField;
      
      public var total:TextField;
      
      private var _id:int;
      
      private var _day:int;
      
      private var _money:int;
      
      private var _accrual:int;
      
      private var _total:int;
      
      private var isClicking:Boolean = false;
      
      public function AdvanceGetBackPanel()
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
         SocketClient.instance.addEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayStore);
         FortuneManagerClient.getInstance().takeAwayAccount(this._id);
      }
      
      private function onTakeAwayStore(param1:SocketClientEvent) : void
      {
         this.isClicking = false;
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayStore);
         var _loc2_:int = int(param1.params.res);
         Beans.update(param1.params);
         if(_loc2_ != -1)
         {
            Beans.got(this._money + _loc2_);
            FortuneManager.getInstance().returnMyStore(this._id);
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
         }
      }
      
      private function onClickReturn(param1:MouseEvent) : void
      {
         FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
      }
      
      public function initPanel(param1:Object) : void
      {
         this._id = param1.id;
         this._day = param1.day;
         this._money = param1.money;
         this._accrual = param1.accrual;
         this._total = this._money + this._accrual;
         TextField(this.getChildByName("day")).text = this._day.toString();
         TextField(this.getChildByName("money")).text = this._money.toString();
         TextField(this.getChildByName("accrual")).text = this._accrual.toString();
         TextField(this.getChildByName("total")).text = this._total.toString();
      }
   }
}

