package mmo.petpackage.service
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.revival.RLog;

   /**
    * REBUILT PetPackageService (pet/newpetpackage, service "PetPackage"; the
    * January 2013 module is lost). Scenes that keep their own control bars ask
    * for it (时空隧道's floors, 实战特训场, the 竞技场 rooms, 潜能之塔): it shows the
    * 亚比 panel of the control bar (NewPetPackage, the rebuilt pet/petpackage).
    */
   public class PetPackageService extends EventDispatcher implements IShowPanel
   {
      public function PetPackageService()
      {
         super();
      }

      public function showPanel():void
      {
         ServiceContainer.instance.tryGetService("NewPetPackage", function(svc:*, o:Object = null):void
         {
            try { if (svc != null) IShowPanel(svc).showPanel(); } catch (e:Error) { RLog.error("PetPackage", e); }
         });
      }
   }
}
