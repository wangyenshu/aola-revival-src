package mmo.feedback
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.feedback.*;
   import mmo.interfaces.feedback.IFeedbackService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FeedbackService. Module feedback/feedback.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.feedback.IFeedbackService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FeedbackService extends EventDispatcher implements IFeedbackService
   {
      public function FeedbackService()
      {
         super();
      }

      public function showFeedBackList() : void
      {
         RLog.stub("FeedbackService.showFeedBackList");
      }

      public function showWeeklyFeedbackPanel(param1:String = null) : void
      {
         RLog.stub("FeedbackService.showWeeklyFeedbackPanel");
      }

      public function getFeedbackProxy(param1:String, param2:String) : IFeedbackProxy
      {
         RLog.stub("FeedbackService.getFeedbackProxy");
         return null;
      }

      public function showReportDialog(param1:String) : void
      {
         RLog.stub("FeedbackService.showReportDialog");
      }

      public function showFeedbackWin(param1:String = "list", param2:Object = null) : void
      {
         RLog.stub("FeedbackService.showFeedbackWin");
      }

   }
}
