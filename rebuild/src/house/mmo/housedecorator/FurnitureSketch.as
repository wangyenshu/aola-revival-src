package mmo.housedecorator
{
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;
   import mmo.houseinterfaces.material.UserMaterialWrap;

   /** REBUILT. The small picture of a piece of furniture in the storage (b<id>_B). */
   public class FurnitureSketch extends MaterialSketch
   {
      public function FurnitureSketch(w:UserMaterialWrap, width:int, height:int)
      {
         super(w, width, height);
         FurnitureViews.instance.addEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         FurnitureViews.instance.getSketch(w.materialId);
      }

      private function onGetSketch(e:MaterialViewCreatorEvent):void
      {
         if (userMaterialWrap == null || e.id != userMaterialWrap.materialId) return;
         FurnitureViews.instance.removeEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         onCreatedRealSketch(e.params.sketch);
      }

      override public function dispose():void
      {
         FurnitureViews.instance.removeEventListener(MaterialViewCreatorEvent.onGetSketch, onGetSketch);
         super.dispose();
      }
   }
}
