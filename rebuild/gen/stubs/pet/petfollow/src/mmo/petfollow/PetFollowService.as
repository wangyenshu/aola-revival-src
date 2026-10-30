package mmo.petfollow
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.follow.*;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetFollowService. Module pet/petfollow.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.follow.IPetFollow) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetFollowService extends EventDispatcher implements IPetFollow
   {
      public function PetFollowService()
      {
         super();
      }

      public function getFollowPet(param1:String) : Object
      {
         RLog.stub("PetFollowService.getFollowPet");
         return {};
      }

      public function setFollow(param1:int, param2:int) : void
      {
         RLog.stub("PetFollowService.setFollow");
      }

      public function setBackPackage() : void
      {
         RLog.stub("PetFollowService.setBackPackage");
      }

      public function init() : void
      {
         RLog.stub("PetFollowService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
