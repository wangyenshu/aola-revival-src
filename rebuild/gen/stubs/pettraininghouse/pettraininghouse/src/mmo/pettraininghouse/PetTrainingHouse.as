package mmo.pettraininghouse
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   import mmo.interfaces.pettraininghouse.*;
   import mmo.interfaces.pettraininghouse.IPetTrainingHouse;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetTrainingHouse. Module pettraininghouse/pettraininghouse.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pettraininghouse.IPetTrainingHouse) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetTrainingHouse extends EventDispatcher implements IPetTrainingHouse
   {
      public function PetTrainingHouse()
      {
         super();
      }

      public function showPetTrainingViewPanel() : void
      {
         RLog.stub("PetTrainingHouse.showPetTrainingViewPanel");
      }

      public function showActualCombatEentrance() : void
      {
         RLog.stub("PetTrainingHouse.showActualCombatEentrance");
      }

      public function showPetObserveMachine() : void
      {
         RLog.stub("PetTrainingHouse.showPetObserveMachine");
      }

      public function showPetTrainingSelectPanel(param1:PetDetailedInfo) : void
      {
         RLog.stub("PetTrainingHouse.showPetTrainingSelectPanel");
      }

      public function init() : void
      {
         RLog.stub("PetTrainingHouse.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
