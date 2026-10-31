package mmo.game.parkour.game.panel
{
   import mmo.game.parkour.common.panel.ParkourConfirmPanel;
   import mmo.game.parkour.config.ParkourResConfig;
   
   public class ParkourPausePanel extends ParkourConfirmPanel
   {
      
      public function ParkourPausePanel(param1:Function = null, param2:Function = null)
      {
         super(ParkourResConfig.PausePanel,param1,param2);
      }
   }
}

