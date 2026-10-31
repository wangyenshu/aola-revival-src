package mmo.game.parkour.config
{
   import mmo.game.parkour.data.role.ParkourRoleAbility;
   import mmo.game.parkour.data.role.ParkourRoleInfo;
   import mmo.game.parkour.data.role.ParkourRoleSkillExcuteTime;
   import mmo.game.parkour.game.roleskill.ParkourFillEmptyRoadSkill;
   import mmo.game.parkour.game.roleskill.ParkourFreeReliveSkill;
   import mmo.game.parkour.game.roleskill.ParkourMaxJumpTimesSkill;
   import mmo.game.parkour.game.roleskill.ParkourOnlyCreateGoldSkill;
   import mmo.game.parkour.game.roleskill.ParkourSetResRoleAbilitySkill;
   import mmo.game.parkour.game.roleskill.ParkourStartFlySkill;
   
   public class ParkourRoleConfig
   {
      
      private static const DefaultUpAblility:ParkourRoleAbility = new ParkourRoleAbility(100,1,200,100,1);
      
      private static const RoleInfos:Array = [new ParkourRoleInfo(1,"酷伊乐",0,null,null,ParkourRoleSkillExcuteTime.None,null,null,new ParkourRoleAbility(1000,20,4000,4000,34),DefaultUpAblility),new ParkourRoleInfo(2,"酷魔兔",8888,"三段跳","三段跳：连续跳跃三次",ParkourRoleSkillExcuteTime.OnAppear,ParkourMaxJumpTimesSkill,{"max":3},new ParkourRoleAbility(2000,30,5000,3000,41),DefaultUpAblility),new ParkourRoleInfo(3,"酷小黑",15000,"点石成金","点石成金：游戏过程中铜币和银币自动转换为金币",ParkourRoleSkillExcuteTime.OnAppear,ParkourOnlyCreateGoldSkill,null,new ParkourRoleAbility(1000,20,4000,4000,35),DefaultUpAblility),new ParkourRoleInfo(4,"酷多多罗",11000,"凌空抽射","凌空抽射：游戏开始时冲刺1000米",ParkourRoleSkillExcuteTime.OnAppear,ParkourStartFlySkill,{"meter":1000},new ParkourRoleAbility(3000,25,2000,3000,45),DefaultUpAblility),new ParkourRoleInfo(5,"酷炎阳",14000,"王者新生","王者新生：第一次死亡时免费复活1 次",ParkourRoleSkillExcuteTime.OnDie,ParkourFreeReliveSkill,{"max":1},new ParkourRoleAbility(3000,25,1500,4000,45),DefaultUpAblility),new ParkourRoleInfo(6,"酷若希",16000,"天外飞仙"
      ,"天外飞仙：游戏开始5000m有浮梯效果",ParkourRoleSkillExcuteTime.OnAppear,ParkourFillEmptyRoadSkill,{"fillMeter":5000},new ParkourRoleAbility(4000,25,2000,2000,46),DefaultUpAblility),new ParkourRoleInfo(7,"酷蓝宝星",14000,"星之引力","星之引力:可以额外延长磁铁时间3S",ParkourRoleSkillExcuteTime.OnAppear,ParkourSetResRoleAbilitySkill,new ParkourRoleAbility(0,0,3000,0,0),new ParkourRoleAbility(3000,30,3000,2000,44),DefaultUpAblility)];
      
      public function ParkourRoleConfig()
      {
         super();
      }
      
      public static function get numOfRole() : int
      {
         return RoleInfos.length;
      }
      
      public static function getRoleInfoById(param1:int) : ParkourRoleInfo
      {
         var _loc2_:ParkourRoleInfo = null;
         for each(_loc2_ in RoleInfos)
         {
            if(_loc2_.id == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }
      
      public static function getRoleInfos(param1:int, param2:int) : Array
      {
         return RoleInfos.slice(param1,param1 + param2);
      }
      
      public static function getRoleInfoClone() : Array
      {
         return RoleInfos.concat();
      }
   }
}

