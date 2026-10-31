package mmo.game.parkour.game.roleskill
{
   import mmo.game.parkour.data.role.ParkourRoleAbility;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourSetResRoleAbilitySkill implements IParkourRoleSkill
   {
      
      public function ParkourSetResRoleAbilitySkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         var _loc2_:ParkourRoleAbility = param1 as ParkourRoleAbility;
         ParkourGameScene.instance.getPlayer().setResRoleAbility(_loc2_);
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

