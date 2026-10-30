package mmo.viparena
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.viparena.*;
   import mmo.interfaces.viparena.IVipArenaService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for VipArenaService. Module viparena.viparenaservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.viparena.IVipArenaService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class VipArenaService extends EventDispatcher implements IVipArenaService
   {
      public function VipArenaService()
      {
         super();
      }

      public function leaveArena(param1:Object) : void
      {
         RLog.stub("VipArenaService.leaveArena");
      }

      public function getCurrentLevel() : int
      {
         RLog.stub("VipArenaService.getCurrentLevel");
         return 0;
      }

      public function addCurrentWildPets(param1:Array) : void
      {
         RLog.stub("VipArenaService.addCurrentWildPets");
      }

      public function joinArena(param1:String, param2:int, param3:Object) : void
      {
         RLog.stub("VipArenaService.joinArena");
      }

      public function getCurrentArenaName() : String
      {
         RLog.stub("VipArenaService.getCurrentArenaName");
         return "";
      }

      public function init() : void
      {
         RLog.stub("VipArenaService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
