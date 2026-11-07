package mmo.plantdecorator
{
   import flash.display.DisplayObject;
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;
   import mmo.houseinterfaces.material.UserMaterialWrap;

   /** REBUILT. The small picture of a tree in the storage (plant/y<id>'s _B). */
   public class PlantSketch extends MaterialSketch
   {
      public function PlantSketch(w:UserMaterialWrap, width:int, height:int)
      {
         super(w, width, height);
         PlantArt.instance.addEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         PlantArt.instance.getSketch(w.materialId);
      }

      private function onGetSketch(e:MaterialViewCreatorEvent):void
      {
         if (userMaterialWrap == null || e.id != userMaterialWrap.materialId) return;
         PlantArt.instance.removeEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         onCreatedRealSketch(e.params.sketch as DisplayObject);
      }

      override public function dispose():void
      {
         PlantArt.instance.removeEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         super.dispose();
      }
   }
}
