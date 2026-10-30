package mmo.peticon
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.peticon.*;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetIconService. Module pet/peticon.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.peticon.IPetIcon) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetIconService extends EventDispatcher implements IPetIcon
   {
      public function PetIconService()
      {
         super();
      }

      public function getPetIcon(param1:int, param2:int = 2, param3:Boolean = true) : PetIconContainer
      {
         RLog.stub("PetIconService.getPetIcon");
         return null;
      }

      public function init() : void
      {
         RLog.stub("PetIconService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
