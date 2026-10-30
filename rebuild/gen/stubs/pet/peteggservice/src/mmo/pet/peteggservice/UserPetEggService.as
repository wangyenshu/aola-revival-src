package mmo.pet.peteggservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.petegg.*;
   import mmo.interfaces.pet.petegg.IUserPetEggService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserPetEggService. Module pet/peteggservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.petegg.IUserPetEggService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserPetEggService extends EventDispatcher implements IUserPetEggService
   {
      public function UserPetEggService()
      {
         super();
      }

      public function removeChecker() : void
      {
         RLog.stub("UserPetEggService.removeChecker");
      }

      public function showPetEggOnlineOrOfflinePanel(param1:String) : void
      {
         RLog.stub("UserPetEggService.showPetEggOnlineOrOfflinePanel");
      }

      public function addChecker() : void
      {
         RLog.stub("UserPetEggService.addChecker");
      }

      public function getEggs(param1:int) : PatchEggs
      {
         RLog.stub("UserPetEggService.getEggs");
         return null;
      }

      public function init() : void
      {
         RLog.stub("UserPetEggService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
