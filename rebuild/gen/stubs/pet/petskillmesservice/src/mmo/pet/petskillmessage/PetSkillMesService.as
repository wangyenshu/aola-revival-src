package mmo.pet.petskillmessage
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.*;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetSkillMesService. Module pet/petskillmesservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.data.IPetSkillMesService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetSkillMesService extends EventDispatcher implements IPetSkillMesService
   {
      public function PetSkillMesService()
      {
         super();
      }

      public function getPetNextForm(param1:int) : Object
      {
         RLog.stub("PetSkillMesService.getPetNextForm");
         return {};
      }

      public function getPetMaxexpByRaceIdAndLevel(param1:int, param2:int) : int
      {
         RLog.stub("PetSkillMesService.getPetMaxexpByRaceIdAndLevel");
         return 0;
      }

      public function compareAttributeRelation(param1:int, param2:int, param3:int = -1) : int
      {
         RLog.stub("PetSkillMesService.compareAttributeRelation");
         return 0;
      }

      public function getAllPetRaceId() : Array
      {
         RLog.stub("PetSkillMesService.getAllPetRaceId");
         return [];
      }

      public function getPetAttributeTipsByRaceId(param1:int) : String
      {
         RLog.stub("PetSkillMesService.getPetAttributeTipsByRaceId");
         return "";
      }

      public function getMaxRaceIdByEggId(param1:int) : int
      {
         RLog.stub("PetSkillMesService.getMaxRaceIdByEggId");
         return 0;
      }

      public function getPetMes(param1:int) : Object
      {
         RLog.stub("PetSkillMesService.getPetMes");
         return {};
      }

      public function getPetSkillMes(param1:int) : Object
      {
         RLog.stub("PetSkillMesService.getPetSkillMes");
         return {};
      }

      public function getPetEggIcon(param1:int) : Sprite
      {
         RLog.stub("PetSkillMesService.getPetEggIcon");
         return null;
      }

      public function getPetAttributeIconByRaceId(param1:int, param2:int = 1) : Sprite
      {
         RLog.stub("PetSkillMesService.getPetAttributeIconByRaceId");
         return null;
      }

      public function getPetEggIconByRaceId(param1:int) : Sprite
      {
         RLog.stub("PetSkillMesService.getPetEggIconByRaceId");
         return null;
      }

      public function getPetPhase(param1:int) : int
      {
         RLog.stub("PetSkillMesService.getPetPhase");
         return 0;
      }

      public function getSkillAttributeIcon(param1:int) : Sprite
      {
         RLog.stub("PetSkillMesService.getSkillAttributeIcon");
         return null;
      }

      public function getPetAttributeTipsByattributeId(param1:int) : String
      {
         RLog.stub("PetSkillMesService.getPetAttributeTipsByattributeId");
         return "";
      }

      public function init() : void
      {
         RLog.stub("PetSkillMesService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
