package mmo.starcoinexchange.fortunemanager
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.revival.starcoin.Beans;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   
   public class ReturnCoinPanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var accrual:TextField;
      
      public var btn_return:SimpleButton;
      
      public var money:TextField;
      
      public var total:TextField;
      
      private var _moneyAccount:int;
      
      private var _accrual:int;
      
      private var _total:int;
      
      public function ReturnCoinPanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         SimpleButton(this.btn_return).addEventListener(MouseEvent.CLICK,this.onClickReturn);
      }
      
      private function onClickReturn(param1:MouseEvent) : void
      {
         Beans.got(this._total);
         FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
      }
      
      public function initPanel(param1:Object) : void
      {
         this._moneyAccount = param1.money;
         this._accrual = param1.accrual;
         this._total = this._moneyAccount + this._accrual;
         TextField(this.getChildByName("money")).text = this._moneyAccount.toString();
         TextField(this.getChildByName("accrual")).text = this._accrual.toString();
         TextField(this.getChildByName("total")).text = this._total.toString();
      }
   }
}

