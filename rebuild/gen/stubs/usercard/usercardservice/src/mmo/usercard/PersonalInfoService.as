package mmo.usercard
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.usercard.*;
   import mmo.interfaces.usercard.IPersonalInfoService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PersonalInfoService. Module usercard/usercardservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.usercard.IPersonalInfoService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PersonalInfoService extends EventDispatcher implements IPersonalInfoService
   {
      public function PersonalInfoService()
      {
         super();
      }

      public function showPersonalInfoPanel() : void
      {
         RLog.stub("PersonalInfoService.showPersonalInfoPanel");
      }

   }
}
