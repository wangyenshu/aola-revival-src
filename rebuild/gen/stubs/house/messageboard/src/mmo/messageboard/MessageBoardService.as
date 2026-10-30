package mmo.messageboard
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.messageboard.*;
   import mmo.interfaces.messageboard.IMessageBoardService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MessageBoardService. Module house/messageboard.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.messageboard.IMessageBoardService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MessageBoardService extends EventDispatcher implements IMessageBoardService
   {
      public function MessageBoardService()
      {
         super();
      }

      public function showMessageBoard(param1:String) : void
      {
         RLog.stub("MessageBoardService.showMessageBoard");
      }

   }
}
