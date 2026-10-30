package mmo.pet.petdictionarydata
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.*;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.explore.ICommonPetExploreDataFactory;
   import mmo.interfaces.pet.data.explore.IRarePetExploreDataFactory;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetDictionaryDataService. Module pet/petdictionarydata.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.data.IPetDictionaryDataService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetDictionaryDataService extends EventDispatcher implements IPetDictionaryDataService
   {
      public function PetDictionaryDataService()
      {
         super();
      }

      public function getCommonPetExplorDataFactory() : ICommonPetExploreDataFactory
      {
         RLog.stub("PetDictionaryDataService.getCommonPetExplorDataFactory");
         return null;
      }

      public function getDataItemByRaceId(param1:int) : PetDictionaryDataItem
      {
         RLog.stub("PetDictionaryDataService.getDataItemByRaceId");
         return null;
      }

      public function getDataItemByPetName(param1:String) : PetDictionaryDataItem
      {
         RLog.stub("PetDictionaryDataService.getDataItemByPetName");
         return null;
      }

      public function getAllDatas() : Object
      {
         RLog.stub("PetDictionaryDataService.getAllDatas");
         return {};
      }

      public function getRarePetExplorDataFactory() : IRarePetExploreDataFactory
      {
         RLog.stub("PetDictionaryDataService.getRarePetExplorDataFactory");
         return null;
      }

      public function init() : void
      {
         RLog.stub("PetDictionaryDataService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
