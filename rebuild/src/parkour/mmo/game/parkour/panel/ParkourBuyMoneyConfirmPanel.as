package mmo.game.parkour.panel
{
   import mmo.common.member.MemberManager;
   import mmo.game.parkour.common.panel.ParkourConfirmPanel;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.loader.common.datastructures.ResourceObject;
   
   public class ParkourBuyMoneyConfirmPanel extends ParkourConfirmPanel
   {
      
      public function ParkourBuyMoneyConfirmPanel(param1:int, param2:Function = null)
      {
         var _loc3_:Boolean = Boolean(MemberManager.instance.isMember()) || Boolean(MemberManager.instance.isTrialMember());
         var _loc4_:ResourceObject = _loc3_ ? ParkourResConfig.MemberBuyMoneyConfirmPanel : ParkourResConfig.NotMemberBuyMoneyConfirmPanel;
         super(ParkourResConfig.MemberBuyMoneyConfirmPanel,param2);
      }
   }
}

