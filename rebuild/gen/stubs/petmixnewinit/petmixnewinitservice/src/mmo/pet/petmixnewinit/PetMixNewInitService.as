package mmo.pet.petmixnewinit
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.*;
   import mmo.interfaces.pet.data.IPetMixInitService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetMixNewInitService. Module petmixnewinit/petmixnewinitservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.data.IPetMixInitService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetMixNewInitService extends EventDispatcher implements IPetMixInitService
   {
      public function PetMixNewInitService()
      {
         super();
      }

      public function getCurSceneCmdStatus() : int
      {
         RLog.stub("PetMixNewInitService.getCurSceneCmdStatus");
         return 0;
      }

      public function getCurSceneCanHatchEggIds() : Array
      {
         RLog.stub("PetMixNewInitService.getCurSceneCanHatchEggIds");
         return [];
      }

      public function init() : void
      {
         RLog.stub("PetMixNewInitService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
