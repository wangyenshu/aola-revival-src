package mmo.petfight.arena
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.IArena;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ArenaService. Module arena/arena.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.IArena) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ArenaService extends EventDispatcher implements IArena
   {
      public function ArenaService()
      {
         super();
      }

      public function showMatchPanel() : void
      {
         RLog.stub("ArenaService.showMatchPanel");
      }

   }
}
