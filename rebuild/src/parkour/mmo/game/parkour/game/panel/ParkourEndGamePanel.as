package mmo.game.parkour.game.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.dailytask.ParkourDailyTaskLogger;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourEndGamePanel extends ParkourPanelBase
   {
      
      private var gameRunTime:int;
      
      private var meter:int;
      
      private var score:int;
      
      private var money:int;
      
      private var logMeter:int;
      
      private var logRank:int;
      
      private var onClose:Function;
      
      private var realScore:int;
      
      public function ParkourEndGamePanel(param1:int, param2:int, param3:int, param4:int, param5:int, param6:int, param7:Function)
      {
         super(ParkourResConfig.EndGamePanel);
         this.gameRunTime = param1;
         this.meter = param2;
         this.score = param3;
         this.money = param4;
         this.logMeter = param5;
         this.logRank = param6;
         this.onClose = param7;
      }
      
      override protected function onShowPanel() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdEndGame,this.onCmdEndGame);
         ParkourClient.endGame(this.gameRunTime,this.meter,this.score);
      }
      
      private function onCmdEndGame(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdEndGame,this.onCmdEndGame);
         this.realScore = param1.params.sc;
         var _loc2_:int = ParkourGameConfig.getLogButton(this.meter);
         SundriesClient.logButton(_loc2_);
         var _loc3_:int = ParkourGameConfig.getEveluateIndex(this.meter);
         ParkourDailyTaskLogger.instance.logEveluate(_loc3_);
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         var _loc1_:MovieClip = panel.getChildByName("mcRole") as MovieClip;
         var _loc2_:TextField = panel.getChildByName("txtMeter") as TextField;
         var _loc3_:TextField = panel.getChildByName("txtScore") as TextField;
         var _loc4_:TextField = panel.getChildByName("txtMoney") as TextField;
         var _loc5_:TextField = panel.getChildByName("txtEvaluate") as TextField;
         _loc1_.gotoAndStop(ParkourGameScene.instance.getPlayer().roleData.id);
         _loc2_.text = this.meter + "";
         _loc3_.text = this.realScore + "";
         _loc4_.text = this.money + "";
         _loc5_.text = ParkourGameConfig.getEveluateDes(this.meter) + "";
      }
      
      override protected function onClickClose() : void
      {
         ParkourHelper.applyFunc(this.onClose);
      }
      
      override protected function onDispose() : void
      {
      }
   }
}

