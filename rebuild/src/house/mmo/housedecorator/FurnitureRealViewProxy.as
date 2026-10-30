package mmo.housedecorator
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.utils.getQualifiedClassName;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.RealViewProxy;

   /**
    * REBUILT. One placed piece of furniture: the children of b<id>_C,
    * ordered top to bottom and left to right, come in pairs per angle
    * (the picture in the room, then the one shown while decorating). Items
    * with behaviour (亚比仓库 …) bring their own b<id>.Container.
    */
   public class FurnitureRealViewProxy extends RealViewProxy
   {
      private var parts:Array;
      private var shown:DisplayObject;
      private var source:Class;

      public function FurnitureRealViewProxy(layout:MaterialLayoutInfo, source:Class)
      {
         this.source = source;
         parts = split(source);
         super(layout);
      }

      private static function split(C:Class):Array
      {
         var box:Sprite = new C() as Sprite;
         var kids:Array = [];
         if (box == null) return [];
         while (box.numChildren > 0) kids.push(box.removeChildAt(0));
         kids.sortOn(["y", "x"], [Array.NUMERIC, Array.NUMERIC]);
         var out:Array = [];
         for (var i:int = 0; i + 1 < kids.length; i += 2) out.push([kids[i], kids[i + 1]]);
         if (kids.length % 2 == 1) out.push([kids[kids.length - 1], kids[kids.length - 1]]);
         return out;
      }

      override protected function createViewContainer():void
      {
         // mmo.furniture::b000007_C -> mmo.furniture.b000007.Container
         var name:String = getQualifiedClassName(source).replace("::", ".").replace("_C", ".Container");
         var C:Class = FurnitureViews.classOf(name);
         onCreateViewContianer(C != null ? Sprite(new C()) : new Sprite());
      }

      override public function get angleCount():int
      {
         return Math.max(1, parts.length);
      }

      override protected function showRealView():*
      {
         if (shown != null && shown.parent == viewContainer) viewContainer.removeChild(shown);
         shown = null;
         if (parts.length == 0) return;
         var pair:Array = parts[Math.min(angle, parts.length - 1)] as Array;
         shown = isEditing ? pair[1] : pair[0];
         shown.x = 0;
         shown.y = 0;
         viewContainer.addChild(shown);
      }

      override public function dispose():void
      {
         super.dispose();
         for each (var pair:Array in parts)
         {
            for each (var d:DisplayObject in pair)
            {
               if (d is MovieClip) MovieClip(d).stop();
               if (d.parent) d.parent.removeChild(d);
            }
         }
         parts = [];
         shown = null;
         source = null;
      }
   }
}
