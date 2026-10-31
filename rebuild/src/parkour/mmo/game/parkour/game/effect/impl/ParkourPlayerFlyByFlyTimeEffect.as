package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   
   public class ParkourPlayerFlyByFlyTimeEffect implements IParkourEffect
   {
      
      private var flyCd:int;
      
      private var countFrame:int;
      
      private var _canDispose:Boolean = false;
      
      public function ParkourPlayerFlyByFlyTimeEffect()
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
         this.flyCd = ParkourGameScene.instance.getPlayer().flyTimeMillSec;
         ParkourGameScene.instance.getPlayer().fly();
      }
      
      public function run() : void
      {
         this.flyCd -= 1000 / ParkourGameConfig.FrameRate;
         if(this.flyCd <= 0)
         {
            this._canDispose = true;
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

