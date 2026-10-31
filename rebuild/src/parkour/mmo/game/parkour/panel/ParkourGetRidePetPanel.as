package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.common.panel.ParkourTipsPanel;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetInfo;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourGetRidePetPanel extends ParkourPanelBase
   {
      
      private var info:ParkourRidePetInfo;
      
      private var fullLvData:ParkourRidePetUserData;
      
      private var onGetRidePet:Function = null;
      
      public function ParkourGetRidePetPanel(param1:ParkourRidePetInfo, param2:Function = null)
      {
         super(ParkourResConfig.GetRidePetPanel);
         this.info = param1;
         this.onGetRidePet = param2;
         this.fullLvData = new ParkourRidePetUserData(param1);
         this.fullLvData.level = ParkourConfig.MaxRidePetLevel;
      }
      
      override protected function onShowPanel() : void
      {
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         ParkourHelper.addRidePetSkillTip(panel,this.info);
         var _loc1_:MovieClip = panel.getChildByName("mcPet") as MovieClip;
         var _loc2_:TextField = panel.getChildByName("txtPrice") as TextField;
         var _loc3_:TextField = panel.getChildByName("txtScorePercent") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtMoneyPercent") as TextField;
         var _loc5_:TextField = panel.getChildByName("txtFlyTime") as TextField;
         var _loc6_:TextField = panel.getChildByName("txtFlyCoinPercent") as TextField;
         var _loc7_:TextField = panel.getChildByName("txtAbsoreTime") as TextField;
         var _loc8_:TextField = panel.getChildByName("txtInvincible") as TextField;
         _loc1_.gotoAndStop(this.info.id);
         _loc3_.text = this.info.baseAbility.scorePercent + "";
         _loc4_.text = this.info.baseAbility.moneyPercent + "";
         _loc2_.text = this.info.price + "";
         var _loc9_:TextField = panel.getChildByName("txtMoney") as TextField;
         _loc9_.text = ParkourUserData.instance.myMoney + "";
         this.refreshProgress(panel.mcFlyTime,this.info.baseAbility.flyTimeMillSec,this.fullLvData.flyTimeMillSec);
         _loc5_.text = this.info.baseAbility.flyTimeSec + "s";
         _loc6_.text = this.info.baseAbility.flyCoinPercent + "%";
         _loc7_.text = this.info.baseAbility.absoreTimeSec + "s";
         _loc8_.text = this.info.baseAbility.invincibleTimeSec + "s";
         this.refreshProgress(panel.mcFlyTime,this.info.baseAbility.flyTimeMillSec,this.fullLvData.flyTimeMillSec);
         this.refreshProgress(panel.mcFlyCoinPercent,this.info.baseAbility.flyCoinPercent,this.fullLvData.flyCoinPercent);
         this.refreshProgress(panel.mcAbsoreTime,this.info.baseAbility.absoreTimeMillSec,this.fullLvData.absoreTimeMillSec);
         this.refreshProgress(panel.mcInvincible,this.info.baseAbility.invincibleTimeMillSec,this.fullLvData.invincibleTimeMillSec);
      }
      
      private function refreshProgress(param1:MovieClip, param2:int, param3:int) : void
      {
         var _loc4_:int = param2 * param1.totalFrames / param3 + 1;
         param1.gotoAndStop(_loc4_);
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnBuy")
         {
            if(ParkourUserData.instance.myMoney < this.info.price)
            {
               new ParkourTipsPanel(ParkourResConfig.LackMoneyPanel).showPanel();
               return;
            }
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(ParkourClient.CmdBuyRidePet,this.onCmdBuyRidePet);
            ParkourClient.buyRidePet(this.info.id);
         }
      }
      
      private function onCmdBuyRidePet(param1:SocketClientEvent) : void
      {
         var _loc3_:Array = null;
         var _loc4_:ParkourRidePetUserData = null;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdBuyRidePet,this.onCmdBuyRidePet);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            _loc3_ = param1.params.bn;
            _loc4_ = new ParkourRidePetUserData(this.info);
            _loc4_.level = 1;
            ParkourUserData.instance.myMoney -= this.info.price;
            ParkourUserData.instance.repaceIntoRidePet(_loc4_);
            ParkourHelper.applyFunc(this.onGetRidePet);
            ShowBonusHelper.showBonus(_loc3_,close);
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

