package mmo.fbservice
{
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.fb.IClearCondition;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   public class FbEventListener
   {
      
      private static var _instance:FbEventListener;
      
      private var listening:Boolean = false;
      
      private var conditionTable:Array = [];
      
      public function FbEventListener()
      {
         super();
      }
      
      public static function get instance() : FbEventListener
      {
         if(_instance == null)
         {
            _instance = new FbEventListener();
         }
         return _instance;
      }
      
      public function startListen() : void
      {
         if(this.listening)
         {
            return;
         }
         this.listening = true;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      public function stopListen() : void
      {
         if(!this.listening)
         {
            return;
         }
         this.listening = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      public function addCondition(param1:IClearCondition) : void
      {
         this.conditionTable.push(param1);
      }
      
      public function removeCondition(param1:IClearCondition) : void
      {
         var _loc2_:int = this.conditionTable.indexOf(param1);
         this.conditionTable.splice(_loc2_,1);
      }
      
      public function clearConditionAndStopListen() : void
      {
         this.conditionTable = [];
         this.listening = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:IClearCondition = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         if(param1.isWin)
         {
            _loc3_ = 0;
            while(_loc3_ < this.conditionTable.length)
            {
               _loc2_ = this.conditionTable[_loc3_] as IClearCondition;
               if(_loc2_.handleFbEvent(param1.raceId))
               {
                  if(_loc2_.isClear)
                  {
                     this.conditionTable.splice(_loc3_,1);
                  }
                  break;
               }
               _loc3_++;
            }
         }
         else if(param1.isEscape)
         {
            _loc4_ = 0;
            while(_loc4_ < this.conditionTable.length)
            {
               _loc2_ = this.conditionTable[_loc4_] as IClearCondition;
               if(Boolean(_loc2_.isKillAll) && Boolean(_loc2_.hasPet(param1.raceId)))
               {
                  _loc2_.handleResetPet();
                  break;
               }
               _loc4_++;
            }
         }
      }
   }
}

