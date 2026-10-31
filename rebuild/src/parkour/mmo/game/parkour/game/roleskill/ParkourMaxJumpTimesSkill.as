package mmo.game.parkour.game.roleskill
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourMaxJumpTimesSkill implements IParkourRoleSkill
   {
      
      public function ParkourMaxJumpTimesSkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         var _loc2_:int = int(param1.max);
         ParkourGameScene.instance.getPlayer().param.maxJumpTime = _loc2_;
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

