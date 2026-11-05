package mmo.peticon
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;

   /**
    * REBUILT pet/peticon (ServiceConfig "PetIconService", IPetIcon; the January
    * 2013 module is lost). The 2013 interfaces' PetIconContainer does the work
    * (it loads peticon/peticon<id> and shows its _L, _S or _F picture): the
    * service hands one out. Panels that show a 亚比's picture this way (天赋启迪,
    * 亚比融合, the 图鉴 and others) needed it. A mod's 亚比 gets its own (ModPetIcon), and so
    * does one the 2013 class does not list (LaterPetIcon).
    */
   public class PetIconService extends EventDispatcher implements IPetIcon
   {
      public function PetIconService()
      {
         super();
      }

      public function getPetIcon(viewId:int, type:int = 2, load:Boolean = true):PetIconContainer
      {
         // A mod's 亚比: its own picture.
         if (ModPetIcon.has(viewId)) return new ModPetIcon(viewId, type, load);
         // One the 2013 list leaves out (it would show 兔小子): its own picture.
         if (LaterPetIcon.needs(viewId)) return new LaterPetIcon(viewId, type, load);
         return new PetIconContainer(viewId, type, load);
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }
   }
}
