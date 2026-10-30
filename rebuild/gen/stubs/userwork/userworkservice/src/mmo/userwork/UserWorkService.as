package mmo.userwork
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.userwork.*;
   import mmo.interfaces.userwork.IUserWorkService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserWorkService. Module userwork/userworkservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.userwork.IUserWorkService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserWorkService extends EventDispatcher implements IUserWorkService
   {
      public function UserWorkService()
      {
         super();
      }

      public function initUserWord(param1:int) : void
      {
         RLog.stub("UserWorkService.initUserWord");
      }

   }
}
