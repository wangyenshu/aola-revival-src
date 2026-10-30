package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.materialdata.PlantData;
   import mmo.interfaces.material.plant.Plant;
   import mmo.interfaces.material.plant.PlantLevel;

   /**
    * The trees of the 植树盆: their June 2012 pictures plant/y<6-digit id>.swf.
    * mmo.plant.y<id>_B is the small picture (the shop's); mmo.plant.y<id>_C
    * holds every picture of the grown tree in pairs, normal and edit view,
    * which the era PlantViewParser takes in order of y then x; which one a
    * tree shows is the era TreePanel.plantSetView's choice: its level while
    * young, then two per level from the mature level on (with fruit, without).
    * Levels and prices are the January 2013 materialdata PlantData.
    */
   public class TreeArt
   {
      public static const IDS:Array = [1, 2, 3, 4, 5, 6, 7, 8];

      public static function plant(id:int):Plant
      {
         return PlantData.data[String(id)] as Plant;
      }

      /** PlantData.level for this plant, by level. */
      public static function levels(id:int):Array
      {
         var out:Array = [];
         for each (var l:PlantLevel in PlantData.level)
         {
            if (l.plantId == id) out[l.level] = l;
         }
         return out;
      }

      private static function sixDigits(id:int):String
      {
         var s:String = String(id);
         while (s.length < 6) s = "0" + s;
         return s;
      }

      /** done(C:Class) once plant/y<id> is loaded; kind "_C" (the tree) or "_B" (the small picture). */
      public static function load(id:int, kind:String, done:Function):void
      {
         var cls:String = "mmo.plant.y" + sixDigits(id) + kind;
         var give:Function = function(d:* = null):void
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls)) done(getDefinitionByName(cls) as Class);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) give();
         else ResScheduler.getResource("plant/y" + sixDigits(id), give, cls, function(e:* = null):void {});
      }

      /** Which of the tree's pictures, as TreePanel.plantSetView. */
      public static function pictureIndex(id:int, level:int, hasFruit:Boolean):int
      {
         var p:Plant = plant(id);
         var mature:int = p ? p.matruelev : 3;
         if (level < mature) return level;
         return mature + 2 * (level - mature) + (hasFruit ? 0 : 1);
      }

      /** The tree's picture for that state, its foot at (0, 0). */
      public static function picture(C:Class, index:int):DisplayObject
      {
         var box:DisplayObjectContainer = new C() as DisplayObjectContainer;
         if (box == null) return null;
         var parts:Array = [];
         for (var i:int = 0; i < box.numChildren; i++) parts.push(box.getChildAt(i));
         parts.sortOn(["y", "x"], [Array.NUMERIC, Array.NUMERIC]);
         var at:int = Math.max(0, Math.min(index, int(parts.length / 2) - 1)) * 2;
         var pic:DisplayObject = parts[at] as DisplayObject;
         if (pic == null) return null;
         box.removeChild(pic);
         pic.x = 0;
         pic.y = 0;
         if (pic is DisplayObjectContainer) DisplayObjectContainer(pic).mouseChildren = false;
         return pic;
      }

      /** A picture scaled to fit w × h, its foot at the bottom middle. */
      public static function fit(pic:DisplayObject, w:Number, h:Number, grow:Boolean = false):Sprite
      {
         var s:Sprite = new Sprite();
         s.addChild(pic);
         var b:Object = pic.getBounds(pic);
         var k:Number = Math.min(w / Math.max(1, b.width), h / Math.max(1, b.height));
         if (!grow) k = Math.min(1, k);
         pic.scaleX = pic.scaleY = k;
         pic.x = -(b.left + b.width / 2) * k;
         pic.y = -b.bottom * k;
         return s;
      }
   }
}
