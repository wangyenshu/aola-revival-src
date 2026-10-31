package mmo.game.parkour.game.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.material.MaterialResultDialogHelper;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.Commands;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourDiePanel extends ParkourPanelBase
   {
      
      private var reliveTimes:int;
      
      private var gameRunTime:int;
      
      private var meter:int;
      
      private var score:int;
      
      private var money:int;
      
      private var logMeter:int;
      
      private var logRank:int;
      
      private var onClose:Function = null;
      
      public function ParkourDiePanel(param1:int, param2:int, param3:int, param4:int, param5:int, param6:int, param7:int, param8:Function = null)
      {
         super(ParkourResConfig.DiePanel);
         this.reliveTimes = param1;
         this.gameRunTime = param2;
         this.meter = param3;
         this.score = param4;
         this.money = param5;
         this.logMeter = param6;
         this.logRank = param7;
         this.onClose = param8;
      }
      
      override protected function onShowPanel() : void
      {
         SundriesClient.logOpen(ParkourConfig.LogBuy);
         SocketClient.instance.addEventListener(Commands.onXingBiUpdated,this.onXingBiUpdate);
         this.refresh();
         showThisPanel();
      }
      
      private function onXingBiUpdate(param1:SocketClientEvent) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:TextField = panel.getChildByName("txtXingbi") as TextField;
         _loc1_.text = UserInfo.xingbi + "";
         var _loc2_:MovieClip = panel.getChildByName("mcPrice") as MovieClip;
         _loc2_.gotoAndStop(this.reliveTimes + 1);
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnRelive")
         {
            this.relive();
         }
      }
      
      override protected function onClickClose() : void
      {
         ParkourHelper.applyFunc(this.onClose);
      }
      
      private function relive() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdRelive,this.onCmdRelive);
         var _loc1_:int = ParkourGameScene.instance.getPlayer().roleData.id;
         var _loc2_:int = ParkourGameScene.instance.getPlayer().ridePetData.info.id;
         ParkourClient.relive(_loc1_,_loc2_,this.gameRunTime,this.meter,this.score);
      }
      
      private function onCmdRelive(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdRelive,this.onCmdRelive);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            close();
            SundriesClient.logBuy(ParkourConfig.LogBuy,1,[[this.reliveTimes,50,2320]]);
            ParkourGameScene.instance.relive();
         }
         else
         {
            MaterialResultDialogHelper.showMaterialResultDialog(_loc2_,true);
         }
      }
      
      override protected function onDispose() : void
      {
         SocketClient.instance.removeEventListener(Commands.onXingBiUpdated,this.onXingBiUpdate);
      }
   }
}

