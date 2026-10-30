package mmo.mailbox
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.mailbox.*;
   import mmo.interfaces.mailbox.IMailboxService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MailboxService. Module mailbox/mailboxservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.mailbox.IMailboxService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MailboxService extends EventDispatcher implements IMailboxService
   {
      public function MailboxService()
      {
         super();
      }

      public function getallmail() : Object
      {
         RLog.stub("MailboxService.getallmail");
         return {};
      }

      public function showMailBoxPanel() : void
      {
         RLog.stub("MailboxService.showMailBoxPanel");
      }

      public function getgift(param1:int) : void
      {
         RLog.stub("MailboxService.getgift");
      }

      public function decMail(param1:String) : void
      {
         RLog.stub("MailboxService.decMail");
      }

      public function isGetGift(param1:int) : Boolean
      {
         RLog.stub("MailboxService.isGetGift");
         return false;
      }

      public function readMail(param1:int) : void
      {
         RLog.stub("MailboxService.readMail");
      }

      public function sendLetter(param1:String, param2:String, param3:String, param4:int) : void
      {
         RLog.stub("MailboxService.sendLetter");
      }

      public function init() : void
      {
         RLog.stub("MailboxService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
