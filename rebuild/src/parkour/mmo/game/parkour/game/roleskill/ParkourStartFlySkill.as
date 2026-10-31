package mmo.game.parkour.game.roleskill
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.avatar.AvatarActionCodeHelper;
   import mmo.game.parkour.game.effect.impl.ParkourPlayerFlyByFlyMeterEffect;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourStartFlySkill implements IParkourRoleSkill
   {
      
      private var flyMeter:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourStartFlySkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         this.flyMeter.setValue(param1.meter);
      }
      
      public function validate() : Boolean
      {
         return true;
      }
      
      public function excute(param1:Object) : void
      {
         var params:Object = param1;
         var onFlyEnd:Function = function():void
         {
            ParkourGameScene.instance.getPlayer().roleAction(AvatarActionCodeHelper.ROLE_NORMAL);
         };
         ParkourGameScene.instance.getPlayer().roleAction(AvatarActionCodeHelper.ROLE_SKILL);
         ParkourGameScene.instance.getEffectManager().excuteEffect(ParkourPlayerFlyByFlyMeterEffect,{
            "flyMeter":this.flyMeter.getValue(),
            "onFlyEnd":onFlyEnd
         });
      }
   }
}

