package mmo.housedecorator
{
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import mmo.houseinterfaces.material.IMaterialViewCreator;
   import mmo.houseinterfaces.material.MaterialViewCreatorEvent;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT. Furniture graphics: furniture/b<id>.swf holds
    * mmo.furniture.b<id>_C (the item, one normal + one decorating picture per
    * angle) and mmo.furniture.b<id>_B (the small picture in the storage).
    * Answers with MaterialViewCreatorEvent, synchronously when the file is
    * already loaded.
    */
   public class FurnitureViews extends EventDispatcher implements IMaterialViewCreator
   {
      public static const instance:FurnitureViews = new FurnitureViews();

      public static function id6(id:int):String
      {
         var s:String = String(id);
         while (s.length < 6) s = "0" + s;
         return s;
      }

      public static function viewClassName(id:int):String
      {
         return "mmo.furniture.b" + id6(id) + "_C";
      }

      public function getView(id:int):DisplayObject
      {
         return fetch(id, viewClassName(id), MaterialViewCreatorEvent.onGetView, "view");
      }

      public function getSketch(id:int):DisplayObject
      {
         return fetch(id, "mmo.furniture.b" + id6(id) + "_B", MaterialViewCreatorEvent.onGetSketch, "sketch");
      }

      private function fetch(id:int, cls:String, type:String, key:String):DisplayObject
      {
         var d:DisplayObject = make(cls);
         if (d != null)
         {
            answer(id, type, key, d);
            return d;
         }
         ResScheduler.getResource("furniture/b" + id6(id), function(o:*):void
         {
            var made:DisplayObject = make(cls);
            if (made != null) answer(id, type, key, made);
         }, cls, function(e:*):void {});
         return null;
      }

      private function answer(id:int, type:String, key:String, d:DisplayObject):void
      {
         var params:Object = {};
         params[key] = d;
         dispatchEvent(new MaterialViewCreatorEvent(type, id, params));
      }

      private static function make(cls:String):DisplayObject
      {
         var dom:ApplicationDomain = ApplicationDomain.currentDomain;
         if (!dom.hasDefinition(cls)) return null;
         var C:Class = dom.getDefinition(cls) as Class;
         return new C() as DisplayObject;
      }

      public static function classOf(cls:String):Class
      {
         var dom:ApplicationDomain = ApplicationDomain.currentDomain;
         return dom.hasDefinition(cls) ? dom.getDefinition(cls) as Class : null;
      }
   }
}
