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
      private static var named:Boolean;

      public function PetDictionaryDataService()
      {
         super();
      }

      public function init():void
      {
         table();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /**
       * The later table writes the 亚比 a species evolves from as ##id_name## ("由##1_兔小子##进化
       * 得来。"): its PetDictionaryDataItem puts the name there, the 2013 one shows the text as it
       * is. The items with one are made again with the name.
       */
      private static function table():Object
      {
         var data:Object = PetDictionaryData.data;
         if (named) return data;
         named = true;
         for (var k:String in data)
         {
            var it:PetDictionaryDataItem = data[k] as PetDictionaryDataItem;
            if (it == null || it.getWay.indexOf("##") < 0) continue;
            data[k] = new PetDictionaryDataItem(String(it.petID), it.petName, it.petHeight, it.petWieght, it.defAttribute, it.attAttribute,
               it.evolutionLevel, it.isNew ? "1" : "0", it.isRare ? "1" : "0", it.loc, it.getWay.replace(/##\d+_([^#]*)##/g, "$1"),
               it.petFavourite, it.petIntro, String(it.petSerieId), String(it.petFormId), it.locations);
         }
         return data;
      }

      public function getDataItemByRaceId(raceId:int):PetDictionaryDataItem
      {
         return table()[String(raceId)] as PetDictionaryDataItem;
      }

      public function getDataItemByPetName(name:String):PetDictionaryDataItem
      {
         if (byName == null)
         {
            byName = {};
            for each (var it:PetDictionaryDataItem in table()) if (byName[it.petName] == null) byName[it.petName] = it;
         }
         return byName[name] as PetDictionaryDataItem;
      }

      public function getAllDatas():Object
      {
         return table();
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
