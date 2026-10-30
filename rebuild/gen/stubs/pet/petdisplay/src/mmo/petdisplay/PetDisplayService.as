package mmo.petdisplay
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.geom.Point;
   import mmo.houseinterfaces.IHouseService;
   import mmo.houseinterfaces.decorate.*;
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.changeable.*;
   import mmo.interfaces.changeable.IChangeableCollection;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetDisplayService. Module pet/petdisplay.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.decorate.IHouseDecorator) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetDisplayService extends EventDispatcher implements IHouseDecorator
   {
      public function PetDisplayService()
      {
         super();
      }

      public function preDecorate(param1:IHouseService) : void
      {
         RLog.stub("PetDisplayService.preDecorate");
      }

      public function resetHouse(param1:int, param2:int) : void
      {
         RLog.stub("PetDisplayService.resetHouse");
      }

      public function getSketch(param1:UserMaterialWrap, param2:int, param3:int) : MaterialSketch
      {
         RLog.stub("PetDisplayService.getSketch");
         return null;
      }

      public function buildView(param1:UserMaterialWrap, param2:Point) : MaterialView
      {
         RLog.stub("PetDisplayService.buildView");
         return null;
      }

      public function save() : void
      {
         RLog.stub("PetDisplayService.save");
      }

      public function close() : void
      {
         RLog.stub("PetDisplayService.close");
      }

      public function getStorageItems() : Array
      {
         RLog.stub("PetDisplayService.getStorageItems");
         return [];
      }

      public function decorate() : void
      {
         RLog.stub("PetDisplayService.decorate");
      }

      public function unUse(param1:MaterialView) : void
      {
         RLog.stub("PetDisplayService.unUse");
      }

      public function addObject(param1:IChangeableObject) : void
      {
         RLog.stub("PetDisplayService.addObject");
      }

      public function removeObject(param1:IChangeableObject) : void
      {
         RLog.stub("PetDisplayService.removeObject");
      }

      public function getObjects() : Array
      {
         RLog.stub("PetDisplayService.getObjects");
         return [];
      }

   }
}
