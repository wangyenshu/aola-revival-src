package mmo.revival.starcoin
{
   import flash.display.Sprite;
   import mmo.starcoinexchange.StarCoinPanelService;
   import mmo.starcoinexchange.StarCoinPanelWithReturnService;
   import mmo.starcoinexchange.fortunemanager.AdvanceGetBackPanel;
   import mmo.starcoinexchange.fortunemanager.FortunemanagerPanel;
   import mmo.starcoinexchange.fortunemanager.OneDayGetBackPanel;
   import mmo.starcoinexchange.fortunemanager.ReturnCoinPanel;
   import mmo.starcoinexchange.fortunemanager.StoreCoinPanel;
   import mmo.starcoinexchange.fortunemanager.StoreMessagePanel;
   import mmo.starcoinexchange.fortunemanager.SurePanel;
   import mmo.starcoinexchange.panel.AoExchangePanel;
   import mmo.starcoinexchange.panel.ExchangePanel;
   import mmo.starcoinexchange.panel.PieceExchangePanel;
   import mmo.starcoinexchange.panel.PieceToCoinConfirmPanel;
   import starcoin_fla.BubbleMovie;
   import starcoin_fla.Pic480;
   import starcoin_fla.Szkljdksw71;

   /**
    * fortunemanager/starcoin on the 2013 libraries (aola-revival): the later module's 星币
    * exchange machine (its ExchangePanel: 奥币铸造星币, 碎片铸造星币 and the 财富小管家's 晶豆储蓄),
    * its decompiled code on its own art. The real-money 购买星币 panel it opened first is left out.
    */
   [SWF(width="960", height="560", backgroundColor="#666666", frameRate="21")]
   public class DocStarCoin extends Sprite
   {
      public function DocStarCoin()
      {
         super();
      }

      private static function compileme():void
      {
         var a:StarCoinPanelService = null;
         var b:StarCoinPanelWithReturnService = null;
         var c:Array = [ExchangePanel, AoExchangePanel, PieceExchangePanel, PieceToCoinConfirmPanel, FortunemanagerPanel,
            StoreMessagePanel, StoreCoinPanel, SurePanel, ReturnCoinPanel, AdvanceGetBackPanel, OneDayGetBackPanel,
            BubbleMovie, Pic480, Szkljdksw71];
      }
   }
}
