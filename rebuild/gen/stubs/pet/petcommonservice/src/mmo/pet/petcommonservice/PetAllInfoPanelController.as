package mmo.pet.petcommonservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.petcommon.*;
   import mmo.interfaces.pet.petcommon.IPetAllInfoPanelController;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetAllInfoPanelController. Module pet/petcommonservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.petcommon.IPetAllInfoPanelController) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetAllInfoPanelController extends EventDispatcher implements IPetAllInfoPanelController
   {
      public function PetAllInfoPanelController()
      {
         super();
      }

      public function getPetInfoObj() : Object
      {
         RLog.stub("PetAllInfoPanelController.getPetInfoObj");
         return {};
      }

      public function setPetInfoObj(param1:Object) : void
      {
         RLog.stub("PetAllInfoPanelController.setPetInfoObj");
      }

      public function clear() : void
      {
         RLog.stub("PetAllInfoPanelController.clear");
      }

      public function init(param1:Sprite) : void
      {
         RLog.stub("PetAllInfoPanelController.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
