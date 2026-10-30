package mmo.robarena
{
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.IRobArena;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for RobArenaService. Module robarena/robarenaservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.IRobArena) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class RobArenaService extends EventDispatcher implements IRobArena
   {
      private var _isInRobArena:Boolean = false;
      public function RobArenaService()
      {
         super();
      }

      public function getNum(param1:String) : int
      {
         RLog.stub("RobArenaService.getNum");
         return 0;
      }

      public function get isInRobArena() : Boolean
      {
         RLog.stub("RobArenaService.isInRobArena");
         return this._isInRobArena;
      }

      public function getRateMc() : MovieClip
      {
         RLog.stub("RobArenaService.getRateMc");
         return null;
      }

      public function showRobArenaPanel() : void
      {
         RLog.stub("RobArenaService.showRobArenaPanel");
      }

      public function getTimeMc() : MovieClip
      {
         RLog.stub("RobArenaService.getTimeMc");
         return null;
      }

      public function getLeftTime() : int
      {
         RLog.stub("RobArenaService.getLeftTime");
         return 0;
      }

      public function getTokenIcon() : MovieClip
      {
         RLog.stub("RobArenaService.getTokenIcon");
         return null;
      }

   }
}
