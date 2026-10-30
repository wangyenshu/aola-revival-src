package mmo.peteggtips
{
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.petegg.*;
   import mmo.interfaces.pet.petegg.IPetEggTipsService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetEggTipsService. Module pet/peteggtipsservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.petegg.IPetEggTipsService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetEggTipsService extends EventDispatcher implements IPetEggTipsService
   {
      public function PetEggTipsService()
      {
         super();
      }

      public function removePetEggTips(param1:DisplayObject) : void
      {
         RLog.stub("PetEggTipsService.removePetEggTips");
      }

      public function addPetEggTips(param1:DisplayObject, param2:int, param3:int = 1) : void
      {
         RLog.stub("PetEggTipsService.addPetEggTips");
      }

   }
}
