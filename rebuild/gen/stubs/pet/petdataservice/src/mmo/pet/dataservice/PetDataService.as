package mmo.pet.dataservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.*;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetDataService. Module pet/petdataservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.data.IPetDataService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetDataService extends EventDispatcher implements IPetDataService
   {
      public function PetDataService()
      {
         super();
      }

      public function checkSinglePetPPIsFull(param1:PetBriefInfo) : Boolean
      {
         RLog.stub("PetDataService.checkSinglePetPPIsFull");
         return false;
      }

      public function setCurRidePetId(param1:int) : void
      {
         RLog.stub("PetDataService.setCurRidePetId");
      }

      public function checkAllPetPPIsFull() : Boolean
      {
         RLog.stub("PetDataService.checkAllPetPPIsFull");
         return false;
      }

      public function checkAllPetHPIsFull() : Boolean
      {
         RLog.stub("PetDataService.checkAllPetHPIsFull");
         return false;
      }

      public function getSelectPetId() : int
      {
         RLog.stub("PetDataService.getSelectPetId");
         return 0;
      }

      public function checkPetIsEmpty() : Boolean
      {
         RLog.stub("PetDataService.checkPetIsEmpty");
         return false;
      }

      public function deletePetByPetId(param1:int) : void
      {
         RLog.stub("PetDataService.deletePetByPetId");
      }

      public function getMyInfo() : PlayerBriefInfo
      {
         RLog.stub("PetDataService.getMyInfo");
         return null;
      }

      public function setCurPmHpPPFull() : void
      {
         RLog.stub("PetDataService.setCurPmHpPPFull");
      }

      public function setAllPmHpPPFull() : void
      {
         RLog.stub("PetDataService.setAllPmHpPPFull");
      }

      public function getMyPets() : Array
      {
         RLog.stub("PetDataService.getMyPets");
         return [];
      }

      public function hasAvailablePet() : Boolean
      {
         RLog.stub("PetDataService.hasAvailablePet");
         return false;
      }

      public function getCurRidePetId() : int
      {
         RLog.stub("PetDataService.getCurRidePetId");
         return 0;
      }

      public function getPetDetailedInfoById(param1:int) : PetDetailedInfo
      {
         RLog.stub("PetDataService.getPetDetailedInfoById");
         return null;
      }

      public function getPetByPetId(param1:int) : PetBriefInfo
      {
         RLog.stub("PetDataService.getPetByPetId");
         return null;
      }

      public function setSelectPetId(param1:int) : void
      {
         RLog.stub("PetDataService.setSelectPetId");
      }

      public function recureAllPet(param1:Function = null) : void
      {
         RLog.stub("PetDataService.recureAllPet");
      }

      public function setPMExp(param1:int) : void
      {
         RLog.stub("PetDataService.setPMExp");
      }

      public function getCurFollowPetId() : int
      {
         RLog.stub("PetDataService.getCurFollowPetId");
         return 0;
      }

      public function init() : void
      {
         RLog.stub("PetDataService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
