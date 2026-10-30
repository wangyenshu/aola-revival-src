package mmo.shoot.effect
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.geom.Point;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.effects.*;
   import mmo.interfaces.shoot.effects.IShootEffectService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ShootEffectService. Module shoot/shooteffectservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.shoot.effects.IShootEffectService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ShootEffectService extends EventDispatcher implements IShootEffectService
   {
      public function ShootEffectService()
      {
         super();
      }

      public function cancelCollect() : void
      {
         RLog.stub("ShootEffectService.cancelCollect");
      }

      public function collect(param1:String, param2:Point, param3:int, param4:int, param5:Function = null, param6:* = null) : void
      {
         RLog.stub("ShootEffectService.collect");
      }

      public function shoot(param1:String, param2:int, param3:IShootEffectTarget, param4:ShootInfo, param5:Function = null, param6:* = null) : void
      {
         RLog.stub("ShootEffectService.shoot");
      }

   }
}
