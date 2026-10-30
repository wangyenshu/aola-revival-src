package mmo.title
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.title.*;
   import mmo.interfaces.title.ITitleService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TitleService. Module title/titleservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.title.ITitleService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TitleService extends EventDispatcher implements ITitleService
   {
      public function TitleService()
      {
         super();
      }

      public function getTitleNameByNo(param1:int) : String
      {
         RLog.stub("TitleService.getTitleNameByNo");
         return "";
      }

      public function showPanel() : void
      {
         RLog.stub("TitleService.showPanel");
      }

      public function getOrderArr() : Array
      {
         RLog.stub("TitleService.getOrderArr");
         return [];
      }

      public function setmytitle(param1:int, param2:Object = null) : void
      {
         RLog.stub("TitleService.setmytitle");
      }

      public function setSelectedTitleNo(param1:int) : void
      {
         RLog.stub("TitleService.setSelectedTitleNo");
      }

      public function getCurTitle() : int
      {
         RLog.stub("TitleService.getCurTitle");
         return 0;
      }

      public function getTitleArr() : Array
      {
         RLog.stub("TitleService.getTitleArr");
         return [];
      }

      public function init() : void
      {
         RLog.stub("TitleService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
