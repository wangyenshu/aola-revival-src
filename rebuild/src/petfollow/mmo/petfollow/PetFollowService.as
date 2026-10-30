package mmo.petfollow
{
   import flash.display.Sprite;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient2;
   import mmo.interfaces.IService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.follow.IPetFollow;
   import mmo.interfaces.pet.follow.PetFollowEvent;

   /**
    * REBUILT pet/petfollow (ServiceConfig "PetFollowService", SingleLocator):
    * the 亚比 that walks behind its owner. The 2013 module is lost; it is
    * written against the 2013 IPetFollow and the 2013 PetClient2 commands
    * 54_8 (setPetFollow {pi}) and 54_9 (setPetBackPackage), the same shape as
    * the later module of this name.
    */
   public class PetFollowService extends Sprite implements IPetFollow
   {
      private static var _instance:PetFollowService;

      public function PetFollowService()
      {
         super();
      }

      public function getInstance():IService
      {
         return _instance;
      }

      public function init():void
      {
         _instance = this;
         PetFollowManager.instance.init();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /** The PetFollowAvatar walking behind this player, if any. */
      public function getFollowPet(userName:String):Object
      {
         return PetFollowManager.pets[userName];
      }

      /** Let my 亚比 petId (of race raceId) follow me. */
      public function setFollow(petId:int, raceId:int):void
      {
         if (petId <= 0) return;
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         if (data != null && data.getCurFollowPetId() == petId) return;
         PetFollowManager.instance.petId = petId;
         PetClient2.instance.setPetFollow(petId);
      }

      /** Send my following 亚比 back into the bag. */
      public function setBackPackage():void
      {
         PetClient2.instance.setPetBackPackage();
         CommonEventDispatcher.instance.dispatchEvent(new PetFollowEvent(PetFollowEvent.SET_UNFOLLOW, {}));
      }
   }
}
