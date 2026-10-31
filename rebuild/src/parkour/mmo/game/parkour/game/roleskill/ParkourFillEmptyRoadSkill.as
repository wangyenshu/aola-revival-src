package mmo.game.parkour.game.roleskill
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.avatar.AvatarActionCodeHelper;
   import mmo.game.parkour.game.effect.impl.ParkourFillEmptyRoadEffect;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourFillEmptyRoadSkill implements IParkourRoleSkill
   {
      
      private var fillMeter:int = 0;
      
      private var hadExcuted:Boolean = false;
      
      public function ParkourFillEmptyRoadSkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         this.fillMeter = param1.fillMeter;
      }
      
      public function validate() : Boolean
      {
         return !this.hadExcuted;
      }
      
      public function excute(param1:Object) : void
      {
         var onEnd:Function;
         var params:Object = param1;
         this.hadExcuted = true;
         onEnd = function():void
         {
            ParkourGameScene.instance.getPlayer().roleAction(AvatarActionCodeHelper.ROLE_NORMAL);
         };
         ParkourGameScene.instance.getPlayer().roleAction(AvatarActionCodeHelper.ROLE_SKILL);
         ParkourGameScene.instance.getEffectManager().excuteEffect(ParkourFillEmptyRoadEffect,{
            "fillMeter":this.fillMeter,
            "onEnd":onEnd
         });
      }
   }
}

