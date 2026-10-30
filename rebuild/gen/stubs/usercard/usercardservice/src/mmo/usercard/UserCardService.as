package mmo.usercard
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.usercard.*;
   import mmo.interfaces.usercard.IUserCardService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserCardService. Module usercard/usercardservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.usercard.IUserCardService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserCardService extends EventDispatcher implements IUserCardService
   {
      public function UserCardService()
      {
         super();
      }

      public function showUserCard(param1:String, param2:int = 1) : void
      {
         RLog.stub("UserCardService.showUserCard");
      }

      public function closeUserCard() : void
      {
         RLog.stub("UserCardService.closeUserCard");
      }

   }
}
