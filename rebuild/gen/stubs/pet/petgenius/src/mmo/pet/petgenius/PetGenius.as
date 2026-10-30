package mmo.pet.petgenius
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IShowPanel;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetGenius. Module pet/petgenius.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.IShowPanel) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetGenius extends EventDispatcher implements IShowPanel
   {
      public function PetGenius()
      {
         super();
      }

      public function showPanel() : void
      {
         RLog.stub("PetGenius.showPanel");
      }

   }
}
