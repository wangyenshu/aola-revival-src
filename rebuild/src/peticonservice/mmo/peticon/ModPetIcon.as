package mmo.peticon
{
   import flash.display.DisplayObject;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.revival.RDef;

   /**
    * REVIVAL. The picture of a mod's 亚比 (docs/MODDING.md), given to panels
    * as the interfaces' PetIconContainer is (that one would load
    * peticon/peticon<id> and, its ids being the game's, show another 亚比).
    */
   public class ModPetIcon extends PetIconContainer
   {
      private var race:int;
      private var kind:int;
      private var shown:Boolean;

      public function ModPetIcon(race:int, kind:int, load:Boolean)
      {
         super(race, kind, false);
         this.race = race;
         this.kind = kind;
         if (load) startLoad();
      }

      public static function has(race:int):Boolean
      {
         return race >= 900001 && race <= 999999 && RDef.has("mmo.pet.peticon" + race + "_L");
      }

      override public function startLoad():void
      {
         if (shown) return;
         shown = true;
         while (numChildren > 0) removeChildAt(0);
         var d:DisplayObject = RDef.make("mmo.pet.peticon" + race + "_L") as DisplayObject;
         if (d != null) addChild(d);
         dispatchEvent(new PetIconEvent(PetIconEvent.ON_ICON_LOADED, race, kind));
      }
   }
}
