package mmo.anticheat
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.anticheat.*;
   import mmo.interfaces.anticheat.IAntiCheatService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for AntiCheatService. Module anticheat/anticheat.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.anticheat.IAntiCheatService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class AntiCheatService extends EventDispatcher implements IAntiCheatService
   {
      public function AntiCheatService()
      {
         super();
      }

      public function showAntiCheatPanel() : void
      {
         RLog.stub("AntiCheatService.showAntiCheatPanel");
      }

   }
}
