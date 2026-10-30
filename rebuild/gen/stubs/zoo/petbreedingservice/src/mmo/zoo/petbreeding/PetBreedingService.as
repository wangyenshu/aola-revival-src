package mmo.zoo.petbreeding
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
    * REBUILT STUB for PetBreedingService. Module zoo/petbreedingservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.decorate.IHouseDecorator) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetBreedingService extends EventDispatcher implements IHouseDecorator
   {
      public function PetBreedingService()
      {
         super();
      }

      public function preDecorate(param1:IHouseService) : void
      {
         RLog.stub("PetBreedingService.preDecorate");
      }

      public function resetHouse(param1:int, param2:int) : void
      {
         RLog.stub("PetBreedingService.resetHouse");
      }

      public function getSketch(param1:UserMaterialWrap, param2:int, param3:int) : MaterialSketch
      {
         RLog.stub("PetBreedingService.getSketch");
         return null;
      }

      public function buildView(param1:UserMaterialWrap, param2:Point) : MaterialView
      {
         RLog.stub("PetBreedingService.buildView");
         return null;
      }

      public function save() : void
      {
         RLog.stub("PetBreedingService.save");
      }

      public function close() : void
      {
         RLog.stub("PetBreedingService.close");
      }

      public function getStorageItems() : Array
      {
         RLog.stub("PetBreedingService.getStorageItems");
         return [];
      }

      public function decorate() : void
      {
         RLog.stub("PetBreedingService.decorate");
      }

      public function unUse(param1:MaterialView) : void
      {
         RLog.stub("PetBreedingService.unUse");
      }

      public function addObject(param1:IChangeableObject) : void
      {
         RLog.stub("PetBreedingService.addObject");
      }

      public function removeObject(param1:IChangeableObject) : void
      {
         RLog.stub("PetBreedingService.removeObject");
      }

      public function getObjects() : Array
      {
         RLog.stub("PetBreedingService.getObjects");
         return [];
      }

   }
}
