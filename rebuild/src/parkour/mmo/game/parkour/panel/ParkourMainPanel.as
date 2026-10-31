package mmo.game.parkour.panel
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.simplemoviehelper.ShowMovieOrCartoonHelper;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.game.parkour.panel.ui.ParkourMainLoveUI;
   import mmo.game.parkour.panel.ui.ParkourMainRankUI;
   import mmo.game.parkour.panel.ui.ParkourMainRoleAndRidePetUI;
   import mmo.play.scene.SceneManager;
   import mmo.util.component.artnumber.ArtNumberManager;
   
   public class ParkourMainPanel extends ParkourPanelBase
   {
      
      private static const UnPlay:Array = ["mcTab_1"];
      
      private var rankUI:ParkourMainRankUI;
      
      private var roleAndRidePetUI:ParkourMainRoleAndRidePetUI;
      
      private var loveUI:ParkourMainLoveUI;
      
      public function ParkourMainPanel()
      {
         super(ParkourResConfig.MainPanel);
      }
      
      override protected function onShowPanel() : void
      {
         SundriesClient.logEvent(11400);
         this.checkUnPlay(panel);
         this.rankUI = new ParkourMainRankUI(panel);
         this.roleAndRidePetUI = new ParkourMainRoleAndRidePetUI(panel.mcRoleAndRidePet);
         this.loveUI = new ParkourMainLoveUI(panel.mcLove);
         this.refresh();
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdGetMainInfo,this.onCmdGetMainInfo);
         ParkourClient.getMainInfo();
      }
      
      private function onCmdGetMainInfo(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdGetMainInfo,this.onCmdGetMainInfo);
         this.rankUI.parseParams(param1.params);
         ParkourUserData.instance.parseParams(param1.params);
         this.loveUI.onInit();
         this.refresh();
         ParkourUserData.instance.addEventListener(ParkourUserData.OnDataUpdate,this.onDataUpdate);
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("XingZuanTask_FinishTask",{"key":"kupaoxingshijie"}));
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("SuperTurnEggMachine_FinishTask",{"key":"kupaoxingshijie"}));
         ShowMovieOrCartoonHelper.showMovieOrCartoon(true,ParkourResConfig.FirstMovie.resPath,ParkourResConfig.FirstMovie.clsName,this.show,"Parkour_FirstMovie");
      }
      
      private function show() : void
      {
         showThisPanel();
         if(!ParkourUserData.instance.singUpData.hadSignUpToday())
         {
            new ParkourDailySignUpPanel().showPanel();
         }
      }
      
      private function checkUnPlay(param1:DisplayObject) : void
      {
         var _loc2_:DisplayObjectContainer = null;
         var _loc3_:int = 0;
         var _loc4_:DisplayObject = null;
         this.checkOneUnPlay(param1);
         if(param1 is DisplayObjectContainer)
         {
            _loc2_ = param1 as DisplayObjectContainer;
            _loc3_ = 0;
            while(_loc3_ < _loc2_.numChildren)
            {
               _loc4_ = _loc2_.getChildAt(_loc3_);
               this.checkUnPlay(_loc4_);
               _loc3_++;
            }
         }
      }
      
      private function checkOneUnPlay(param1:DisplayObject) : void
      {
         if(UnPlay.indexOf(param1.name) != -1)
         {
            DisplayUtil.applyGray(param1);
            if(param1 is InteractiveObject)
            {
               TipsManager.getInstance().addTips(param1 as InteractiveObject,"敬请期待");
            }
            DisplayUtil.stop(param1);
            if(param1 is SimpleButton)
            {
               (param1 as SimpleButton).enabled = false;
            }
            if(param1 is Sprite)
            {
               (param1 as Sprite).mouseChildren = false;
            }
         }
      }
      
      private function onDataUpdate(param1:Event) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         this.loveUI.refresh();
         this.refreshUsedRole();
         this.refreshUsedRidePet();
         this.roleAndRidePetUI.refresh();
         var _loc1_:ParkourRoleUserData = ParkourUserData.instance.getSelectedRoleData();
         var _loc2_:ParkourRidePetUserData = ParkourUserData.instance.getSelectedRidePetData();
         ParkourHelper.setMcButton(panel.mcRoleAndRidePet.mcPlay,!_loc1_.isExit && !ParkourUserData.instance.isRentingRole(_loc1_.id),"快去租用" + _loc1_.getInfo().name);
         ParkourHelper.setMcButton(panel.mcRoleAndRidePet.mcRent,_loc1_.isExit || ParkourUserData.instance.isRentingRole(_loc1_.id),"你已经可以使用" + _loc1_.getInfo().name);
         var _loc3_:TextField = panel.getChildByName("txtMoney") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtRunDistance") as TextField;
         _loc3_.text = ParkourUserData.instance.myMoney + "";
         _loc4_.text = ParkourUserData.instance.totalRunDistance + "";
         var _loc5_:int = ParkourUserData.instance.myRank;
         var _loc6_:TextField = panel.getChildByName("txtMyRank") as TextField;
         var _loc7_:TextField = panel.getChildByName("txtMyRankMoveMeter") as TextField;
         _loc7_.text = ParkourUserData.instance.myHightestDistance + "";
         _loc6_.text = _loc5_ == -1 ? "未上榜" : _loc5_.toString();
         var _loc8_:MovieClip = panel.getChildByName("mcRewardNum") as MovieClip;
         this.showNum(_loc8_.mcNum,ParkourUserData.instance.rewardNum);
         _loc8_.visible = ParkourUserData.instance.rewardNum != 0;
         var _loc9_:MovieClip = panel.getChildByName("mcDailyTaskNum") as MovieClip;
         this.showNum(_loc9_.mcNum,ParkourUserData.instance.numOfDailyTask);
         _loc9_.visible = ParkourUserData.instance.numOfDailyTask != 0;
         TipsManager.getInstance().addTips(panel.mcMoney,"金币");
      }
      
      private function showNum(param1:MovieClip, param2:int) : void
      {
         var _loc3_:Array = [param1.mc0,param1.mc1];
         ArtNumberManager.setNumber(_loc3_,param2);
      }
      
      private function refreshUsedRole() : void
      {
         var _loc1_:MovieClip = panel.getChildByName("mcSelectedRole") as MovieClip;
         var _loc2_:MovieClip = _loc1_.getChildByName("mcRoleView") as MovieClip;
         var _loc3_:TextField = _loc1_.getChildByName("txtLevel") as TextField;
         var _loc4_:ParkourRoleUserData = ParkourUserData.instance.getSelectedRoleData();
         var _loc5_:MovieClip = panel.getChildByName("mcViewBackGround") as MovieClip;
         _loc1_.visible = _loc4_ != null;
         _loc2_.gotoAndStop(1);
         _loc5_.gotoAndStop(1);
         _loc5_.visible = _loc4_ != null;
         if(_loc4_ != null)
         {
            _loc5_.gotoAndStop(_loc4_.id);
            _loc2_.gotoAndStop(_loc4_.id);
            _loc3_.text = "Lv." + ParkourUserData.instance.getSelectedRoleData().level + "";
         }
      }
      
      private function refreshUsedRidePet() : void
      {
         var _loc1_:MovieClip = panel.getChildByName("mcSelectedRidePet") as MovieClip;
         var _loc2_:ParkourRidePetUserData = ParkourUserData.instance.getSelectedRidePetData();
         _loc1_.visible = _loc2_ != null;
         if(_loc2_ != null)
         {
            _loc1_.gotoAndStop(_loc2_.info.id);
         }
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnPlay")
         {
            if(ParkourUserData.instance.myLove <= 0)
            {
               NewDialog.showFailMessage("你的星星能量爱心不足!!");
               return;
            }
            new ParkourSelectMapPanel().showPanel();
         }
         else if(param1 == "btnBuyMoney")
         {
            new ParkourBuyMoneyPanel().showPanel();
         }
         else if(param1 == "btnBuyLove")
         {
            new ParkourBuyLovePanel().showPanel();
         }
         else if(param1 == "btnReward")
         {
            new ParkourRewardPanel().showPanel();
         }
         else if(param1 == "btnRewardList")
         {
            new ParkourRewardListPanel().showPanel();
         }
         else if(param1 == "btnTask")
         {
            new ParkourDailyTaskPanel().showPanel();
         }
         else if(param1 == "btnRent")
         {
            new ParkourRentRoleConfirmPanel(ParkourUserData.instance.getSelectedRoleData().getInfo()).showPanel();
         }
      }
      
      override protected function onClickClose() : void
      {
         SceneManager.getInstance().unloadGame();
         ParkourUserData.instance.dispose();
      }
      
      override protected function onDispose() : void
      {
         ParkourUserData.instance.removeEventListener(ParkourUserData.OnDataUpdate,this.onDataUpdate);
         this.loveUI.dispose();
         this.rankUI.dispose();
         this.roleAndRidePetUI.dispose();
      }
   }
}

