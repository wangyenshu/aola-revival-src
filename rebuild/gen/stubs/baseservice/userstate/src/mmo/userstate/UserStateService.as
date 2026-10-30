package mmo.userstate
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.userstate.*;
   import mmo.interfaces.userstate.IUserStateService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserStateService. Module baseservice/userstate.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.userstate.IUserStateService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserStateService extends EventDispatcher implements IUserStateService
   {
      public function UserStateService()
      {
         super();
      }

      public function clearMyState() : void
      {
         RLog.stub("UserStateService.clearMyState");
      }

      public function setMyState(param1:int, param2:String = "") : void
      {
         RLog.stub("UserStateService.setMyState");
      }

      public function getUserState(param1:String) : UserStateInfo
      {
         RLog.stub("UserStateService.getUserState");
         return null;
      }

      public function init() : void
      {
         RLog.stub("UserStateService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
