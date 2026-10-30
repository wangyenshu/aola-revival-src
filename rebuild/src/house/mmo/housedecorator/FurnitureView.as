package mmo.housedecorator
{
   import flash.utils.getQualifiedClassName;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;

   /** REBUILT. A piece of furniture in a home (MaterialView of the 2013 houseinterfaces). */
   public class FurnitureView extends MaterialView
   {
      public function FurnitureView(layout:MaterialLayoutInfo)
      {
         super(layout);
      }

      override protected function createRealView():void
      {
         FurnitureViews.instance.addEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
         FurnitureViews.instance.getView(layoutInfo.source.materialId);
      }

      private function onGetView(e:MaterialViewCreatorEvent):void
      {
         if (isDisposed)
         {
            FurnitureViews.instance.removeEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
            return;
         }
         if (e.id != layoutInfo.source.materialId) return;
         FurnitureViews.instance.removeEventListener(MaterialViewCreatorEvent.onGetView, onGetView);
         var C:Class = FurnitureViews.classOf(getQualifiedClassName(e.params.view).replace("::", "."));
         if (C == null) return;
         onCreatedRealView(new FurnitureRealViewProxy(layoutInfo, C));
      }
   }
}
