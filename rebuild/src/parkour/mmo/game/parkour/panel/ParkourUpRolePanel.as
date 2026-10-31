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
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourUpRolePanel extends ParkourPanelBase
   {
      
      private var data:ParkourRoleUserData;
      
      private var onUpRole:Function = null;
      
      private var fullLvData:ParkourRoleUserData;
      
      private var nextLvData:ParkourRoleUserData;
      
      public function ParkourUpRolePanel(param1:ParkourRoleUserData, param2:Function = null)
      {
         super(ParkourResConfig.UpRolePanel);
         this.onUpRole = param2;
         this.setRoleData(param1);
      }
      
      private function setRoleData(param1:ParkourRoleUserData) : void
      {
         this.data = param1;
         this.fullLvData = param1.cloneDataByLevel(ParkourConfig.MaxRoleLevel);
         if(param1.level < ParkourConfig.MaxRoleLevel)
         {
            this.nextLvData = param1.cloneDataByLevel(param1.level + 1);
         }
      }
      
      override protected function onShowPanel() : void
      {
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         ParkourHelper.addRoleSkillTip(panel,this.data.getInfo());
         var _loc1_:MovieClip = panel.getChildByName("mcPet") as MovieClip;
         var _loc2_:MovieClip = panel.getChildByName("mcSkill") as MovieClip;
         var _loc3_:TextField = panel.getChildByName("txtLevel") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtExp") as TextField;
         var _loc5_:TextField = panel.getChildByName("txtPrice") as TextField;
         var _loc6_:TextField = panel.getChildByName("txtSuperCool") as TextField;
         var _loc7_:TextField = panel.getChildByName("txtFlyTime") as TextField;
         var _loc8_:TextField = panel.getChildByName("txtFlyCoinPercent") as TextField;
         var _loc9_:TextField = panel.getChildByName("txtAbsoreTime") as TextField;
         var _loc10_:TextField = panel.getChildByName("txtInvincible") as TextField;
         var _loc11_:TextField = panel.getChildByName("txtAddFlyTime") as TextField;
         var _loc12_:TextField = panel.getChildByName("txtAddFlyCoinPercent") as TextField;
         var _loc13_:TextField = panel.getChildByName("txtAddAbsoreTime") as TextField;
         var _loc14_:TextField = panel.getChildByName("txtAddInvincible") as TextField;
         ParkourHelper.setRoleView(_loc1_,this.data.id);
         ParkourHelper.setRoleView(_loc2_,this.data.id);
         _loc3_.text = this.data.level + "";
         _loc4_.text = this.data.exp + "/" + this.data.nextLvNeedExp;
         this.refreshProgress(panel.mcExp,this.data.exp,this.data.nextLvNeedExp);
         _loc5_.text = this.data.nextLvNeedMoney + "";
         _loc6_.text = this.data.superCool + "";
         _loc7_.text = this.data.flyTimeSec + "s";
         _loc8_.text = this.data.flyCoinPercent + "%";
         _loc9_.text = this.data.absoreTimeSec + "s";
         _loc10_.text = this.data.invincibleTimeSec + "s";
         if(this.nextLvData == null)
         {
            _loc11_.text = "+0s";
            _loc12_.text = "+0%";
            _loc13_.text = "+0s";
            _loc14_.text = "+0s";
         }
         else
         {
            _loc11_.text = ParkourHelper.millSecToSec(this.nextLvData.flyTimeMillSec - this.data.flyTimeMillSec).toString() + "s";
            _loc12_.text = this.nextLvData.flyCoinPercent - this.data.flyCoinPercent + "%";
            _loc13_.text = ParkourHelper.millSecToSec(this.nextLvData.absoreTimeMillSec - this.data.absoreTimeMillSec).toString() + "s";
            _loc14_.text = ParkourHelper.millSecToSec(this.nextLvData.invincibleTimeMillSec - this.data.invincibleTimeMillSec).toString() + "s";
         }
         this.refreshProgress(panel.mcFlyTime,this.data.flyTimeMillSec,this.fullLvData.flyTimeMillSec);
         this.refreshProgress(panel.mcFlyCoinPercent,this.data.flyCoinPercent,this.fullLvData.flyCoinPercent);
         this.refreshProgress(panel.mcAbsoreTime,this.data.absoreTimeMillSec,this.fullLvData.absoreTimeMillSec);
         this.refreshProgress(panel.mcInvincible,this.data.invincibleTimeMillSec,this.fullLvData.invincibleTimeMillSec);
         ParkourHelper.setMcButton(panel.mcUpLevel,this.data.level >= ParkourConfig.MaxRoleLevel,"你的角色已经是最高等级了，不能再升级了!");
      }
      
      private function refreshProgress(param1:MovieClip, param2:int, param3:int) : void
      {
         var _loc4_:int = param2 * param1.totalFrames / param3 + 1;
         param1.gotoAndStop(_loc4_);
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnUpLevel")
         {
            if(ParkourUserData.instance.myMoney < this.data.nextLvNeedMoney)
            {
               new ParkourTipsPanel(ParkourResConfig.LackMoneyPanel).showPanel();
               return;
            }
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(ParkourClient.CmdUpRoleLevel,this.onCmdUpLevel);
            ParkourClient.upRoleLevel(this.data.id);
         }
      }
      
      private function onCmdUpLevel(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdUpRoleLevel,this.onCmdUpLevel);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            ParkourUserData.instance.myMoney -= this.data.nextLvNeedMoney;
            ParkourUserData.instance.repaceIntoRole(this.nextLvData);
            ParkourHelper.applyFunc(this.onUpRole);
            this.setRoleData(this.nextLvData);
            this.refresh();
            NewDialog.showSucceedMessage("升级成功");
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

