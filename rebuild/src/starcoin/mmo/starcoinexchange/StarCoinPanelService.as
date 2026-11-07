package mmo.starcoinexchange
{
   import flash.display.Sprite;
   import mmo.interfaces.IShowDataPanel;
   import mmo.interfaces.IShowPanel;
   import mmo.starcoinexchange.panel.ExchangePanel;

   /**
    * The later module's service (fortunemanager/starcoin). Its showPanel opened the real-money
    * 购买星币 panel (NewBuyXingBiPanel), which the revival leaves out: it opens the exchange
    * machine's 奥币铸造星币 tab instead, and showPanelByData its tabs as before
    * (zhuZaoTabIndex, quickOpenAoBi; tabIndex, the 购买星币 panel's own, is the first tab).
    */
   public class StarCoinPanelService extends Sprite implements IShowPanel, IShowDataPanel
   {
      public function StarCoinPanelService()
      {
         super();
      }

      public function showPanel():void
      {
         new ExchangePanel().showPanelByData({"tabIndex": 0});
      }

      public function showPanelByData(param1:Object):void
      {
         var tab:int = param1 != null && param1.hasOwnProperty("zhuZaoTabIndex") ? int(param1["zhuZaoTabIndex"]) : 0;
         if (tab < 0 || tab > 2) tab = 0;
         new ExchangePanel().showPanelByData({"tabIndex": tab});
      }

      public function dispose():void
      {
      }
   }
}
