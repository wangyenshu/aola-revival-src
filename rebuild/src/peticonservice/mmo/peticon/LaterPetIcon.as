package mmo.peticon
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RPetIcon;

   /**
    * REVIVAL. The picture of a 亚比 the 2013 PetIconContainer does not list: its ids end at 1426
    * (and skip 1002 and 1423), and any other id shows 兔小子 (peticon1). The revival has the
    * species to 1651 and every one's peticon/peticon<id>; this loads it the way the 2013 class
    * loads the listed ones (ids above 10000 are their form's species, as there).
    */
   public class LaterPetIcon extends PetIconContainer
   {
      private var race:int;
      private var kind:int;
      private var asked:Boolean;

      public function LaterPetIcon(race:int, kind:int, load:Boolean)
      {
         super(race, kind, false);
         this.race = race;
         while (this.race > 10000) this.race -= 10000;
         this.kind = kind;
         if (load) startLoad();
      }

      /** Is the species one the 2013 list leaves out? */
      public static function needs(race:int):Boolean
      {
         while (race > 10000) race -= 10000;
         return race > 1426 || race == 1002 || race == 1423;
      }

      override public function startLoad():void
      {
         if (asked) return;
         asked = true;
         var cls:String = "mmo.pet.peticon" + race + (kind == PetIconType.FIGHT ? "_F" : kind == PetIconType.SMALL ? "_S" : "_L");
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) show(cls);
         else ResScheduler.getResource("peticon/peticon" + race, function(d:DisplayObject):void { show(cls); });
      }

      private function show(cls:String):void
      {
         // The waiting movie the 2013 class put in.
         while (numChildren > 0)
         {
            var w:MovieClip = getChildAt(0) as MovieClip;
            if (w != null) w.stop();
            removeChildAt(0);
         }
         var d:DisplayObject = RPetIcon.make(cls);
         if (d != null)
         {
            if (kind == PetIconType.SMALL)
            {
               // As the 2013 class: drawn at 1.5 times as a bitmap, shown at its size.
               d.scaleX = d.scaleY = 1.5;
               d = DisplayUtil.cacheAsBitmap(d);
               var s:Sprite = new Sprite();
               s.addChild(d);
               s.scaleX = s.scaleY = 1 / 1.5;
               d = s;
            }
            addChild(d);
         }
         dispatchEvent(new PetIconEvent(PetIconEvent.ON_ICON_LOADED, race, kind));
      }
   }
}
