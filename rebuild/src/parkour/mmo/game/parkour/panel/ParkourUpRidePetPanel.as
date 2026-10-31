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
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourUpRidePetPanel extends ParkourPanelBase
   {
      
      private var data:ParkourRidePetUserData;
      
      private var onUpRidePet:Function = null;
      
      private var fullLvData:ParkourRidePetUserData;
      
      private var nextLvData:ParkourRidePetUserData;
      
      public function ParkourUpRidePetPanel(param1:ParkourRidePetUserData, param2:Function = null)
      {
         super(ParkourResConfig.UpRidePetPanel);
         this.onUpRidePet = param2;
         this.setPetRideData(param1);
      }
      
      private function setPetRideData(param1:ParkourRidePetUserData) : void
      {
         this.data = param1;
         this.fullLvData = param1.createDataByLevel(ParkourConfig.MaxRidePetLevel);
         if(param1.level < ParkourConfig.MaxRidePetLevel)
         {
            this.nextLvData = param1.createDataByLevel(param1.level + 1);
         }
      }
      
      override protected function onShowPanel() : void
      {
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         ParkourHelper.addRidePetSkillTip(panel,this.data.info);
         var _loc1_:MovieClip = panel.getChildByName("mcPet") as MovieClip;
         var _loc2_:MovieClip = panel.getChildByName("mSkill") as MovieClip;
         var _loc3_:TextField = panel.getChildByName("txtLevel") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtPrice") as TextField;
         var _loc5_:TextField = panel.getChildByName("txtScorePercent") as TextField;
         var _loc6_:TextField = panel.getChildByName("txtMoneyPercent") as TextField;
         var _loc7_:TextField = panel.getChildByName("txtFlyTime") as TextField;
         var _loc8_:TextField = panel.getChildByName("txtFlyCoinPercent") as TextField;
         var _loc9_:TextField = panel.getChildByName("txtAbsoreTime") as TextField;
         var _loc10_:TextField = panel.getChildByName("txtInvincible") as TextField;
         var _loc11_:TextField = panel.getChildByName("txtAddFlyTime") as TextField;
         var _loc12_:TextField = panel.getChildByName("txtAddFlyCoinPercent") as TextField;
         var _loc13_:TextField = panel.getChildByName("txtAddAbsoreTime") as TextField;
         var _loc14_:TextField = panel.getChildByName("txtAddInvincible") as TextField;
         _loc1_.gotoAndStop(this.data.info.id);
         _loc2_.gotoAndStop(this.data.info.id);
         _loc3_.text = this.data.level + "";
         _loc4_.text = this.data.nextLvNeedMoney + "";
         _loc5_.text = this.data.scorePercent + "%";
         _loc6_.text = this.data.moneyPercent + "%";
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
         ParkourHelper.setMcButton(panel.mcUpLevel,this.data.level >= ParkourConfig.MaxRidePetLevel,"你的角色已经是最高等级了，不能再升级了!");
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
            SocketClient.instance.addEventListener(ParkourClient.CmdUpRidePetLevel,this.onCmdUpLevel);
            ParkourClient.upRidePetLevel(this.data.info.id);
         }
      }
      
      private function onCmdUpLevel(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdUpRidePetLevel,this.onCmdUpLevel);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            ParkourUserData.instance.myMoney -= this.data.nextLvNeedMoney;
            ParkourUserData.instance.repaceIntoRidePet(this.nextLvData);
            ParkourHelper.applyFunc(this.onUpRidePet);
            this.setPetRideData(this.nextLvData);
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

