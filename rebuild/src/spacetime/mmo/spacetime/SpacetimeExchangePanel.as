package mmo.spacetime
{
   import flash.events.EventDispatcher;
   import mmo.common.dialog.NewDialog;
   import mmo.interfaces.IShowPanel;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;

   /**
    * REBUILT SpacetimeExchangePanel (spacetime/spacetimeservice): opens the
    * era exchange panel of the tunnel's 星星 and 月亮 (spacetime/spacetimeexchange,
    * April 2012), as the 时空隧道 scene's own exchange button does.
    */
   public class SpacetimeExchangePanel extends EventDispatcher implements IShowPanel
   {
      public function SpacetimeExchangePanel()
      {
         super();
      }

      public function showPanel():void
      {
         ResScheduler.getResource("spacetime/spacetimeexchange", function(p:*):void
         {
            if (p is IShowPanel) IShowPanel(p).showPanel();
         }, "mmo.spacetimepanel.SpaceTimeExchangePanelNew", function(e:* = null):void { RLog.log("spacetime: no exchange panel"); });
      }
   }
}
