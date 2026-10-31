package mmo.game.parkour.panel
{
   import mmo.game.parkour.common.panel.ParkourConfirmPanel;
   import mmo.game.parkour.config.ParkourResConfig;
   
   public class ParkourBuyLoveConfirmPanel extends ParkourConfirmPanel
   {
      
      public function ParkourBuyLoveConfirmPanel(param1:int, param2:Function = null)
      {
         super(ParkourResConfig.MemberBuyLoveConfirmPanel,param2,null);
      }
   }
}

