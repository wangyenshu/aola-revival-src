package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   
   public class ParkourPlayerAbsoreEffect implements IParkourEffect
   {
      
      private var absoreTimeCd:int;
      
      private var countFrame:int;
      
      private var _canDispose:Boolean = false;
      
      public function ParkourPlayerAbsoreEffect()
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
         this._canDispose = false;
         this.countFrame = 0;
         this.absoreTimeCd = ParkourGameScene.instance.getPlayer().absoreTimeMillSec;
         ParkourGameScene.instance.getPlayer().param.absorbing = true;
      }
      
      public function run() : void
      {
         this.absoreTimeCd -= 1000 / ParkourGameConfig.FrameRate;
         if(this.absoreTimeCd <= 0)
         {
            this._canDispose = true;
            ParkourGameScene.instance.getPlayer().param.absorbing = false;
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

