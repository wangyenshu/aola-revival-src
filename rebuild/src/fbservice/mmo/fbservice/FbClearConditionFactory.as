package mmo.fbservice
{
   import mmo.fbservice.conditions.FightWildPetsCondition;
   import mmo.interfaces.fb.FbClearConditions;
   import mmo.interfaces.fb.IClearCondition;
   
   public class FbClearConditionFactory
   {
      
      private static var _instance:FbClearConditionFactory;
      
      public function FbClearConditionFactory()
      {
         super();
      }
      
      public static function get instance() : FbClearConditionFactory
      {
         if(_instance == null)
         {
            _instance = new FbClearConditionFactory();
         }
         return _instance;
      }
      
      public function createClearCondition(param1:int, param2:Object, param3:Array) : IClearCondition
      {
         switch(param1)
         {
            case FbClearConditions.FIGHT_SPECIFIC_WILD_PETS:
               return this.handleClearWildPetCondition(param2,param3,false);
            case FbClearConditions.FIGHT_ALL_WILD_PETS:
               return this.handleClearWildPetCondition(param2,param3,true);
            default:
               return null;
         }
      }
      
      private function handleClearWildPetCondition(param1:Object, param2:Array, param3:Boolean) : IClearCondition
      {
         var _loc4_:Array = null;
         var _loc5_:Object = null;
         if(param1.pets != null && param1.pets[0] == -1)
         {
            _loc4_ = [];
            for each(_loc5_ in param2)
            {
               _loc4_.push(_loc5_.raceId);
            }
            return new FightWildPetsCondition(_loc4_,param1.callback,param1.context,param3);
         }
         return new FightWildPetsCondition(param1.pets,param1.callback,param1.context,param3);
      }
   }
}

