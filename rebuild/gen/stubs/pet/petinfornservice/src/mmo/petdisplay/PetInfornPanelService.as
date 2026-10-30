package mmo.petdisplay
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.pet.display.*;
   import mmo.interfaces.pet.display.IPetDisplay;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetInfornPanelService. Module pet/petinfornservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.display.IPetDisplay) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetInfornPanelService extends EventDispatcher implements IPetDisplay
   {
      public function PetInfornPanelService()
      {
         super();
      }

      public function showPetPanel(param1:Boolean, param2:int, param3:String, param4:int) : void
      {
         RLog.stub("PetInfornPanelService.showPetPanel");
      }

      public function showPanel() : void
      {
         RLog.stub("PetInfornPanelService.showPanel");
      }

   }
}
