package mmo.wildpet
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.IWildPet;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for WildPetService. Module pet/wildpetservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.IWildPet) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class WildPetService extends EventDispatcher implements IWildPet
   {
      public function WildPetService()
      {
         super();
      }

      public function generatePetsAtCurrentScene(param1:Array) : void
      {
         RLog.stub("WildPetService.generatePetsAtCurrentScene");
      }

      public function setPetsInvisible() : void
      {
         RLog.stub("WildPetService.setPetsInvisible");
      }

      public function generatePet(param1:int) : void
      {
         RLog.stub("WildPetService.generatePet");
      }

      public function setPetsVisible() : void
      {
         RLog.stub("WildPetService.setPetsVisible");
      }

      public function dispose() : void
      {
         RLog.stub("WildPetService.dispose");
      }

      public function init() : void
      {
         RLog.stub("WildPetService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
