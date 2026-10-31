package mmo.game.parkour.game.roleskill
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourOnlyCreateGoldSkill implements IParkourRoleSkill
   {
      
      public function ParkourOnlyCreateGoldSkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         ParkourGameScene.instance.getCoinManager().setOnlyCrateGoldCoin(true);
      }
      
      public function validate() : Boolean
      {
         return false;
      }
      
      public function excute(param1:Object) : void
      {
      }
   }
}

