package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   
   public class GameOverPanel extends MovieClip
   {
      
      private static const CMD_GAME_COUNT:String = "CF160527_submit";
      
      public var txtScore:TextField;
      
      public var btnQuit1:SimpleButton;
      
      public var txtTool:TextField;
      
      public var btnQuit:SimpleButton;
      
      private var getScore:Number = 0;
      
      private var score:TextField;
      
      private var money:TextField;
      
      private var tool:TextField;
      
      public function GameOverPanel(param1:Number, param2:int)
      {
         super();
         SundriesClient.logButton(467,0);
         this.getScore = param1;
         this.score = this.getChildByName("txtScore") as TextField;
         this.tool = this.getChildByName("txtTool") as TextField;
         SimpleButton(this.getChildByName("btnQuit")).addEventListener(MouseEvent.CLICK,this.onClickQuit);
         SimpleButton(this.getChildByName("btnQuit1")).addEventListener(MouseEvent.CLICK,this.onClickQuit);
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(SocketClientEvent.onIncreaseScore,this.onAddScore);
         SocketClient.instance.endGame(this.getScore,param2,true,"gameFlyingFruit");
         // REVIVAL: the score at once (it waited for the 2016 activity's count, HolidayExtension
         // CF160527_submit, which this world has not).
         ProgressFullSprite.close();
         this.score.text = this.getScore + "";
         this.tool.text = "0";
      }
      
      private function onAddScore(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onIncreaseScore,this.onAddScore);
      }
      
      private function onClickQuit(param1:MouseEvent) : void
      {
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("AolaMasterXuanshangTask",{"evt":"fengkuangdeshuiguo"}));
         var _loc2_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         _loc2_.refuseInvite(false);
         param1.stopImmediatePropagation();
         SocketClient.instance.removeEventListener(SocketClientEvent.onIncreaseScore,this.onAddScore);
         CommonEventDispatcher.instance.dispatchEvent(new Event("FLYINGDISK_QUIT_GAME"));
         DisplayUtil.stopAndRemove(this);
      }
      
      private function onClickRestart(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         SocketClient.instance.removeEventListener(SocketClientEvent.onIncreaseScore,this.onAddScore);
         CommonEventDispatcher.instance.dispatchEvent(new Event("FLYINGDISK_RESTART_GAME"));
         DisplayUtil.stopAndRemove(this);
      }
      
      private function sendNewGameCountCmd() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(CMD_GAME_COUNT,this.afterGameCount);
         var _loc1_:int = this.getScore;
         SocketClient.instance.sendXtMessage("HolidayExtension",CMD_GAME_COUNT,{"score":_loc1_});
      }
      
      private function afterGameCount(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(CMD_GAME_COUNT,this.afterGameCount);
         var _loc2_:Object = param1.params;
         var _loc3_:int = 0;
         if(_loc2_.bn != null && _loc2_.bn.length > 0)
         {
            if(_loc2_.bn[0].hasOwnProperty("num"))
            {
               _loc3_ = int(_loc2_.bn[0].num);
            }
         }
         this.score.text = this.getScore + "";
         this.tool.text = _loc3_ + "";
         ShowBonusHelper.showBonus(_loc2_.bn,null);
      }
   }
}

