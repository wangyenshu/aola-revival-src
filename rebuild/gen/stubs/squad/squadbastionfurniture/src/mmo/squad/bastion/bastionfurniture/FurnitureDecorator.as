package mmo.squad.bastion.bastionfurniture
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
    * REBUILT STUB for BastionFurnitureDecorator. Module squad/squadbastionfurniture.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.houseinterfaces.decorate.IHouseDecorator) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FurnitureDecorator extends EventDispatcher implements IHouseDecorator
   {
      public function FurnitureDecorator()
      {
         super();
      }

      public function preDecorate(param1:IHouseService) : void
      {
         RLog.stub("FurnitureDecorator.preDecorate");
      }

      public function resetHouse(param1:int, param2:int) : void
      {
         RLog.stub("FurnitureDecorator.resetHouse");
      }

      public function getSketch(param1:UserMaterialWrap, param2:int, param3:int) : MaterialSketch
      {
         RLog.stub("FurnitureDecorator.getSketch");
         return null;
      }

      public function buildView(param1:UserMaterialWrap, param2:Point) : MaterialView
      {
         RLog.stub("FurnitureDecorator.buildView");
         return null;
      }

      public function save() : void
      {
         RLog.stub("FurnitureDecorator.save");
      }

      public function close() : void
      {
         RLog.stub("FurnitureDecorator.close");
      }

      public function getStorageItems() : Array
      {
         RLog.stub("FurnitureDecorator.getStorageItems");
         return [];
      }

      public function decorate() : void
      {
         RLog.stub("FurnitureDecorator.decorate");
      }

      public function unUse(param1:MaterialView) : void
      {
         RLog.stub("FurnitureDecorator.unUse");
      }

      public function addObject(param1:IChangeableObject) : void
      {
         RLog.stub("FurnitureDecorator.addObject");
      }

      public function removeObject(param1:IChangeableObject) : void
      {
         RLog.stub("FurnitureDecorator.removeObject");
      }

      public function getObjects() : Array
      {
         RLog.stub("FurnitureDecorator.getObjects");
         return [];
      }

   }
}
