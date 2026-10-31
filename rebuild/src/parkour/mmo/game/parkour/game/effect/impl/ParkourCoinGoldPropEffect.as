package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   import mmo.game.parkour.game.sceneitem.coin.ParkourCoin;
   
   public class ParkourCoinGoldPropEffect implements IParkourEffect
   {
      
      private var logMeter:int;
      
      private var areaMeter:int;
      
      private var _canDispose:Boolean = false;
      
      public function ParkourCoinGoldPropEffect()
      {
         super();
      }
      
      public function excute(param1:Object) : Boolean
      {
         this.reset(param1);
         return true;
      }
      
      public function reset(param1:Object) : void
      {
         this.areaMeter = param1.areaMeter;
         this.logMeter = ParkourGameScene.instance.moveMeter;
      }
      
      public function run() : void
      {
         var _loc5_:ParkourCoin = null;
         var _loc1_:int = ParkourGameScene.instance.moveMeter;
         var _loc2_:int = _loc1_ - this.logMeter;
         var _loc3_:int = this.areaMeter * ParkourGameConfig.MeterToPixel;
         var _loc4_:int = _loc2_ * ParkourGameConfig.MeterToPixel;
         for each(_loc5_ in ParkourGameScene.instance.getCoinManager().getAllCoins())
         {
            if(_loc5_.x + _loc4_ <= _loc3_)
            {
               ParkourGameScene.instance.getCoinManager().changetCoinToGold(_loc5_);
            }
         }
         if(_loc2_ >= this.areaMeter)
         {
            this._canDispose = true;
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

