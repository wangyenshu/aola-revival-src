package mmo.MessageSend
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.messagesend.*;
   import mmo.interfaces.messagesend.IMessageSendService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MessageSendService. Module messagesend/messagesendservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.messagesend.IMessageSendService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MessageSendService extends EventDispatcher implements IMessageSendService
   {
      public function MessageSendService()
      {
         super();
      }

      public function init() : void
      {
         RLog.stub("MessageSendService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
