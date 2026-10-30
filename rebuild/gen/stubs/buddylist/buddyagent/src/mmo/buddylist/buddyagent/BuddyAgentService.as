package mmo.buddylist.buddyagent
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.buddy.*;
   import mmo.interfaces.buddy.IBuddyAgentService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BuddyAgentService. Module buddylist/buddyagent.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.buddy.IBuddyAgentService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BuddyAgentService extends EventDispatcher implements IBuddyAgentService
   {
      public function BuddyAgentService()
      {
         super();
      }

      public function getComboBox() : Sprite
      {
         RLog.stub("BuddyAgentService.getComboBox");
         return null;
      }

   }
}
