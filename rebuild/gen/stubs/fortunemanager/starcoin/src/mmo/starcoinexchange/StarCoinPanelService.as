package mmo.starcoinexchange
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IShowPanel;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for StarCoinPanelService. Module fortunemanager/starcoin.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.IShowPanel) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class StarCoinPanelService extends EventDispatcher implements IShowPanel
   {
      public function StarCoinPanelService()
      {
         super();
      }

      public function showPanel() : void
      {
         RLog.stub("StarCoinPanelService.showPanel");
      }

   }
}
