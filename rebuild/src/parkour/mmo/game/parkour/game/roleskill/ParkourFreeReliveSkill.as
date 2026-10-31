package mmo.game.parkour.game.roleskill
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   
   public class ParkourFreeReliveSkill implements IParkourRoleSkill
   {
      
      private var reliveTimes:ConfuseInteger = new ConfuseInteger();
      
      private var maxReliveTimes:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourFreeReliveSkill()
      {
         super();
      }
      
      public function init(param1:Object) : void
      {
         this.maxReliveTimes.setValue(param1.max);
      }
      
      public function validate() : Boolean
      {
         return this.reliveTimes.getValue() < this.maxReliveTimes.getValue();
      }
      
      public function excute(param1:Object) : void
      {
         if(!this.validate())
         {
            return;
         }
         this.reliveTimes.add(1);
         ParkourGameScene.instance.relive(true);
      }
   }
}

