package mmo.plantdecorator
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.materialdata.PlantData;
   import mmo.interfaces.material.plant.Plant;

   /**
    * REBUILT. The pictures of a tree put into a home: its June 2012 plant/y<6-digit id>.swf,
    * mmo.plant.y<id>_C (every picture of the tree in pairs, the one in the room and the one
    * while decorating, in order of y then x) and _B (the small picture, the storage's). A
    * tree made furniture is grown and has no fruit left: the pair the era tree panel showed
    * for its top level without fruit. Answers as the furniture's view creator does
    * (MaterialViewCreatorEvent, by plant id).
    */
   public class PlantArt extends EventDispatcher
   {
      public static const instance:PlantArt = new PlantArt();

      private static function sixDigits(id:int):String
      {
         var s:String = String(id);
         while (s.length < 6) s = "0" + s;
         return s;
      }

      private static function load(id:int, kind:String, done:Function):void
      {
         var cls:String = "mmo.plant.y" + sixDigits(id) + kind;
         var give:Function = function(d:* = null):void
         {
            if (ApplicationDomain.currentDomain.hasDefinition(cls)) done(getDefinitionByName(cls) as Class);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) give();
         else ResScheduler.getResource("plant/y" + sixDigits(id), give, cls, function(e:* = null):void {});
      }

      /** onGetView, params.view: the tree's [picture, picture while decorating]. */
      public function getView(id:int):void
      {
         load(id, "_C", function(C:Class):void
         {
            dispatchEvent(new MaterialViewCreatorEvent(MaterialViewCreatorEvent.onGetView, id, {view: grown(id, C)}));
         });
      }

      /** onGetSketch, params.sketch: the small picture. */
      public function getSketch(id:int):void
      {
         load(id, "_B", function(C:Class):void
         {
            dispatchEvent(new MaterialViewCreatorEvent(MaterialViewCreatorEvent.onGetSketch, id, {sketch: new C() as DisplayObject}));
         });
      }

      /** The pair of pictures for the top level without fruit (as the era TreePanel.plantSetView). */
      private static function grown(id:int, C:Class):Array
      {
         var box:DisplayObjectContainer = new C() as DisplayObjectContainer;
         if (box == null) return [];
         var parts:Array = [];
         while (box.numChildren > 0) parts.push(box.removeChildAt(0));
         parts.sortOn(["y", "x"], [Array.NUMERIC, Array.NUMERIC]);
         var p:Plant = PlantData.data[String(id)] as Plant;
         var top:int = p ? p.maxlevel : 7;
         var mature:int = p ? p.matruelev : 3;
         var index:int = top < mature ? top : mature + 2 * (top - mature) + 1;
         var at:int = Math.max(0, Math.min(index, int(parts.length / 2) - 1)) * 2;
         var out:Array = [];
         for (var i:int = at; i <= at + 1 && i < parts.length; i++)
         {
            var d:DisplayObject = parts[i] as DisplayObject;
            d.x = 0;
            d.y = 0;
            if (d is DisplayObjectContainer) DisplayObjectContainer(d).mouseChildren = false;
            out.push(d);
         }
         if (out.length == 1) out.push(out[0]);
         return out;
      }
   }
}
