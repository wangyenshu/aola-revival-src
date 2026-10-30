package mmo.petpackagesort.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.petpackage.*;
   import mmo.interfaces.pet.petpackage.IPetPackageSort;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetPackageSort. Module pet/petpackagesort.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.petpackage.IPetPackageSort) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetPackageSortService extends EventDispatcher implements IPetPackageSort
   {
      public function PetPackageSortService()
      {
         super();
      }

      public function showPanelByData(param1:Array) : void
      {
         RLog.stub("PetPackageSortService.showPanelByData");
      }

      public function showPanel() : void
      {
         RLog.stub("PetPackageSortService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("PetPackageSortService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

      public function dispose() : void
      {
         RLog.stub("PetPackageSortService.dispose");
      }

   }
}
