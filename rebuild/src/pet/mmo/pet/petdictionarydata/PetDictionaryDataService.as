package mmo.pet.petdictionarydata
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.data.explore.ICommonPetExploreDataFactory;
   import mmo.interfaces.pet.data.explore.IRarePetExploreDataFactory;

   /**
    * REBUILT pet/petdictionarydata (PetDictionaryDataService): the species
    * table of the 亚比 that existed by January 2013 (PetDictionaryData,
    * tools/gen_pets.py from the later table, which the 2013
    * PetDictionaryDataItem reads unchanged).
    */
   public class PetDictionaryDataService extends EventDispatcher implements IPetDictionaryDataService
   {
      private var byName:Object;

      public function PetDictionaryDataService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function getDataItemByRaceId(raceId:int):PetDictionaryDataItem
      {
         return PetDictionaryData.data[String(raceId)] as PetDictionaryDataItem;
      }

      public function getDataItemByPetName(name:String):PetDictionaryDataItem
      {
         if (byName == null)
         {
            byName = {};
            for each (var it:PetDictionaryDataItem in PetDictionaryData.data) if (byName[it.petName] == null) byName[it.petName] = it;
         }
         return byName[name] as PetDictionaryDataItem;
      }

      public function getAllDatas():Object
      {
         return PetDictionaryData.data;
      }

      public function getCommonPetExplorDataFactory():ICommonPetExploreDataFactory
      {
         return null;
      }

      public function getRarePetExplorDataFactory():IRarePetExploreDataFactory
      {
         return null;
      }
   }
}
