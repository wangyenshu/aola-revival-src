package mmo.plantdecorator
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
    * REBUILT STUB for PlantDecorator. Module yz/plantdecorator.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.decorate.IHouseDecorator) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PlantDecorator extends EventDispatcher implements IHouseDecorator
   {
      public function PlantDecorator()
      {
         super();
      }

      public function preDecorate(param1:IHouseService) : void
      {
         RLog.stub("PlantDecorator.preDecorate");
      }

      public function resetHouse(param1:int, param2:int) : void
      {
         RLog.stub("PlantDecorator.resetHouse");
      }

      public function getSketch(param1:UserMaterialWrap, param2:int, param3:int) : MaterialSketch
      {
         RLog.stub("PlantDecorator.getSketch");
         return null;
      }

      public function buildView(param1:UserMaterialWrap, param2:Point) : MaterialView
      {
         RLog.stub("PlantDecorator.buildView");
         return null;
      }

      public function save() : void
      {
         RLog.stub("PlantDecorator.save");
      }

      public function close() : void
      {
         RLog.stub("PlantDecorator.close");
      }

      public function getStorageItems() : Array
      {
         RLog.stub("PlantDecorator.getStorageItems");
         return [];
      }

      public function decorate() : void
      {
         RLog.stub("PlantDecorator.decorate");
      }

      public function unUse(param1:MaterialView) : void
      {
         RLog.stub("PlantDecorator.unUse");
      }

      public function addObject(param1:IChangeableObject) : void
      {
         RLog.stub("PlantDecorator.addObject");
      }

      public function removeObject(param1:IChangeableObject) : void
      {
         RLog.stub("PlantDecorator.removeObject");
      }

      public function getObjects() : Array
      {
         RLog.stub("PlantDecorator.getObjects");
         return [];
      }

   }
}
