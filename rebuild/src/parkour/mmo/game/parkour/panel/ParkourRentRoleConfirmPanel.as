package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.common.panel.ParkourTipsPanel;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.role.ParkourRoleInfo;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRentRoleConfirmPanel extends ParkourPanelBase
   {
      
      private static const Price:int = 200;
      
      private var info:ParkourRoleInfo;
      
      public function ParkourRentRoleConfirmPanel(param1:ParkourRoleInfo)
      {
         this.info = param1;
         super(ParkourResConfig.RentConfirmPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         var _loc1_:MovieClip = panel.getChildByName("mcPet") as MovieClip;
         ParkourHelper.setRoleView(_loc1_,this.info.id);
         var _loc2_:TextField = panel.getChildByName("txtLeftTimes") as TextField;
         _loc2_.text = ParkourUserData.instance.lfetTimesOfRentRole + "";
         var _loc3_:TextField = panel.getChildByName("txtPrice") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtSuperCool") as TextField;
         var _loc5_:TextField = panel.getChildByName("txtSkillName") as TextField;
         var _loc6_:TextField = panel.getChildByName("txtName") as TextField;
         _loc3_.text = this.info.price + "";
         _loc6_.text = this.info.name + "";
         _loc4_.text = this.info.baseAbility.superCool + "";
         _loc5_.text = this.info.skillName + "";
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnOk")
         {
            this.rent();
         }
      }
      
      private function rent() : void
      {
         if(ParkourUserData.instance.myMoney < Price)
         {
            new ParkourTipsPanel(ParkourResConfig.LackMoneyPanel).showPanel();
            return;
         }
         if(ParkourUserData.instance.lfetTimesOfRentRole <= 0)
         {
            NewDialog.showFailMessage("你已经不能再租用角色了!");
            return;
         }
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdRentRole,this.onCmdRentRole);
         ParkourClient.rentRole(this.info.id);
      }
      
      private function onCmdRentRole(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdRentRole,this.onCmdRentRole);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            close();
            ParkourUserData.instance.rentRole(this.info.id);
            --ParkourUserData.instance.lfetTimesOfRentRole;
            ParkourUserData.instance.myMoney -= Price;
         }
         else
         {
            new ParkourTipsPanel(ParkourResConfig.LackMoneyPanel).showPanel();
         }
      }
      
      override protected function onDispose() : void
      {
      }
   }
}

