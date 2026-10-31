package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourPlayerFlyByFlyMeterEffect implements IParkourEffect
   {
      
      private var flyMeter:int = 0;
      
      private var startMeter:int = 0;
      
      private var onFlyEnd:Function = null;
      
      private var _canDispose:Boolean = false;
      
      public function ParkourPlayerFlyByFlyMeterEffect()
      {
         super();
      }
      
      public function excute(param1:Object) : Boolean
      {
         if(ParkourGameScene.instance.getPlayer().isFlying())
         {
            return false;
         }
         this.reset(param1);
         return true;
      }
      
      public function reset(param1:Object) : void
      {
         this.flyMeter = param1.flyMeter;
         this.onFlyEnd = param1.onFlyEnd;
         this._canDispose = false;
         this.startMeter = ParkourGameScene.instance.moveMeter;
         ParkourGameScene.instance.getPlayer().fly();
      }
      
      public function run() : void
      {
         var _loc1_:int = ParkourGameScene.instance.moveMeter;
         if(_loc1_ - this.startMeter > this.flyMeter)
         {
            this._canDispose = true;
            ParkourHelper.applyFunc(this.onFlyEnd);
            ParkourGameScene.instance.getPlayer().land();
         }
      }
      
      public function canDispose() : Boolean
      {
         return this._canDispose;
      }
      
      public function dispose() : void
      {
      }
   }
}

