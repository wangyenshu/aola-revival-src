package mmo.mailbox
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IMailService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MailService. Module mailbox/mailbox.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.IMailService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MailBoxDoc extends EventDispatcher implements IMailService
   {
      public function MailBoxDoc()
      {
         super();
      }

      public function showBox() : void
      {
         RLog.stub("MailBoxDoc.showBox");
      }

   }
}
