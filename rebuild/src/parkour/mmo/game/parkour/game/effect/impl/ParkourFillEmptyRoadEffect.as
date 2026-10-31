package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourFillEmptyRoadEffect implements IParkourEffect
   {
      
      private var fillMeter:int = 0;
      
      private var startMeter:int = 0;
      
      private var _canDispose:Boolean = false;
      
      private var onEnd:Function;
      
      public function ParkourFillEmptyRoadEffect()
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
         this.fillMeter = param1.fillMeter;
         this.onEnd = param1.onEnd;
         this._canDispose = false;
         this.startMeter = ParkourGameScene.instance.moveMeter;
      }
      
      public function run() : void
      {
         var _loc1_:int = ParkourGameScene.instance.moveMeter;
         if(_loc1_ - this.startMeter > this.fillMeter)
         {
            this._canDispose = true;
            ParkourHelper.applyFunc(this.onEnd);
         }
         ParkourGameScene.instance.getRoad().checkFillEmptyRoad();
         ParkourGameScene.instance.getEnemyManager().destroyEnemyUnderEmptyRoadFiller();
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

