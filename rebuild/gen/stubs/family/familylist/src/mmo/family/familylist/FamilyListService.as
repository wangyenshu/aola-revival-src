package mmo.family.familylist
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.interfaces.family.*;
   import mmo.interfaces.family.IFamilyListService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FamilyListService. Module family/familylist.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.family.IFamilyListService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FamilyListService extends EventDispatcher implements IFamilyListService, IServiceLocator, IService
   {
      private static var __instance:FamilyListService;

      public function FamilyListService()
      {
         super();
      }

      public function showFamilyListPanel() : void
      {
         RLog.stub("FamilyListService.showFamilyListPanel");
      }

      public function getInstance() : IService
      {
         if (__instance == null) __instance = new FamilyListService();
         return __instance;
      }

   }
}
