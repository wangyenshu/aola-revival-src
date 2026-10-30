package mmo.petfight.ring
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.text.TextField;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.IFightRing;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FightRingService. Module fightring/fightring.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.IFightRing) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FightRingService extends EventDispatcher implements IFightRing
   {
      public function FightRingService()
      {
         super();
      }

      public function isOwner() : Boolean
      {
         RLog.stub("FightRingService.isOwner");
         return false;
      }

      public function setRing(param1:MovieClip, param2:MovieClip, param3:SimpleButton, param4:TextField, param5:TextField, param6:TextField, param7:TextField) : void
      {
         RLog.stub("FightRingService.setRing");
      }

      public function dispose() : void
      {
         RLog.stub("FightRingService.dispose");
      }

   }
}
