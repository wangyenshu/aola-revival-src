package mmo.pet.petskillmessage
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT: a 亚比蛋 picture, petegg/egg<id> (class mmo.pet.egg<id>), as the
    * later IconContainerBase loads it; when there is no file of that id, the
    * next id of the list (an egg of the 亚比's attribute, then the plain egg,
    * petegg/egg).
    */
   public class EggIcon extends Sprite
   {
      private static const SIZE:Number = 60;
      private var tries:Array;

      public function EggIcon(ids:Array)
      {
         super();
         graphics.beginFill(0xFFFFFF, 0);
         graphics.drawRect(0, 0, SIZE, SIZE);
         graphics.endFill();
         tries = ids.concat([-1]);
         next();
      }

      private function next():void
      {
         if (tries.length == 0) return;
         var id:int = int(tries.shift());
         var file:String = id < 0 ? "petegg/egg" : "petegg/egg" + id;
         var cls:String = id < 0 ? "mmo.pet.egg" : "mmo.pet.egg" + id;
         if (ApplicationDomain.currentDomain.hasDefinition(cls))
         {
            show(new (ApplicationDomain.currentDomain.getDefinition(cls) as Class)() as DisplayObject);
            return;
         }
         ResScheduler.getResource(file, function(d:DisplayObject):void { show(d); }, cls, function(...rest):void { next(); });
      }

      private function show(s:DisplayObject):void
      {
         if (s == null) { next(); return; }
         addChild(s);
         DisplayUtil.scaleDisplay(s, SIZE, SIZE);
         graphics.clear();
      }
   }
}
