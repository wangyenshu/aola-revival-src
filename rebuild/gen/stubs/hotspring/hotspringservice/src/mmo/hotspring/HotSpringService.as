package mmo.hotspring
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.hotspring.*;
   import mmo.interfaces.hotspring.IHotSpringService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for HotSpringService. Module hotspring/hotspringservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.hotspring.IHotSpringService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class HotSpringService extends EventDispatcher implements IHotSpringService
   {
      public function HotSpringService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("HotSpringService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function setUserOut() : void
      {
         RLog.stub("HotSpringService.setUserOut");
      }

      public function setUserIn(param1:int) : void
      {
         RLog.stub("HotSpringService.setUserIn");
      }

      public function setArea(param1:MovieClip) : void
      {
         RLog.stub("HotSpringService.setArea");
      }

      public function showSalePanel() : void
      {
         RLog.stub("HotSpringService.showSalePanel");
      }

      public function showChangePanle() : void
      {
         RLog.stub("HotSpringService.showChangePanle");
      }

      public function dispose() : void
      {
         RLog.stub("HotSpringService.dispose");
      }

      public function showNoticePanel() : void
      {
         RLog.stub("HotSpringService.showNoticePanel");
      }

   }
}
