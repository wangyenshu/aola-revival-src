package mmo.game.parkour.game.effect.impl
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourEffect;
   
   public class ParkourPlayerPowerPropEffect implements IParkourEffect
   {
      
      public function ParkourPlayerPowerPropEffect()
      {
         super();
      }
      
      public function excute(param1:Object) : Boolean
      {
         var _loc2_:int = int(param1.power);
         ParkourGameScene.instance.getPlayer().param.power = ParkourGameScene.instance.getPlayer().param.power + _loc2_;
         return true;
      }
      
      public function reset(param1:Object) : void
      {
      }
      
      public function run() : void
      {
      }
      
      public function canDispose() : Boolean
      {
         return true;
      }
      
      public function dispose() : void
      {
      }
   }
}

