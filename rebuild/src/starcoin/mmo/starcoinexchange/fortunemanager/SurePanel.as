package mmo.starcoinexchange.fortunemanager
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   
   public class SurePanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var btnKnow:SimpleButton;
      
      public var day:TextField;
      
      public var money:TextField;
      
      public function SurePanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         SimpleButton(this.btnKnow).addEventListener(MouseEvent.CLICK,this.onClickKnow);
      }
      
      private function onClickKnow(param1:MouseEvent) : void
      {
         FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
      }
      
      public function initPanel(param1:Object) : void
      {
         TextField(this.money).text = param1.money;
         TextField(this.day).text = param1.day;
      }
   }
}

