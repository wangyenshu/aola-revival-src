package mmo.plantdecorator
{
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;

   /** REBUILT. A tree made furniture, in a home (MaterialView of the 2013 houseinterfaces). */
   public class PlantView extends MaterialView
   {
      public function PlantView(layout:MaterialLayoutInfo)
      {
         super(layout);
      }

      override protected function createRealView():void
      {
         PlantArt.instance.addEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
         PlantArt.instance.getView(layoutInfo.source.materialId);
      }

      private function onGetView(e:MaterialViewCreatorEvent):void
      {
         if (isDisposed)
         {
            PlantArt.instance.removeEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
            return;
         }
         if (e.id != layoutInfo.source.materialId) return;
         PlantArt.instance.removeEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
         onCreatedRealView(new PlantRealViewProxy(layoutInfo, e.params.view as Array));
      }
   }
}
