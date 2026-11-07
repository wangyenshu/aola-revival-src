package mmo.plantdecorator
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.RealViewProxy;

   /** REBUILT. A tree standing in a home: one angle, its picture (another one while decorating). */
   public class PlantRealViewProxy extends RealViewProxy
   {
      private var pair:Array;
      private var shown:DisplayObject;

      public function PlantRealViewProxy(layout:MaterialLayoutInfo, pair:Array)
      {
         this.pair = pair || [];
         super(layout);
      }

      override protected function createViewContainer():void
      {
         onCreateViewContianer(new Sprite());
      }

      override public function get angleCount():int
      {
         return 1;
      }

      override protected function showRealView():*
      {
         if (shown != null && shown.parent == viewContainer) viewContainer.removeChild(shown);
         shown = null;
         if (pair.length == 0) return;
         shown = (isEditing ? pair[pair.length - 1] : pair[0]) as DisplayObject;
         shown.x = 0;
         shown.y = 0;
         viewContainer.addChild(shown);
      }

      override public function dispose():void
      {
         super.dispose();
         for each (var d:DisplayObject in pair)
         {
            if (d is MovieClip) MovieClip(d).stop();
            if (d.parent) d.parent.removeChild(d);
         }
         pair = [];
         shown = null;
      }
   }
}
