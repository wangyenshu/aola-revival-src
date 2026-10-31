package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import mmo.common.ProgressFullSprite;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourDailySignUpPanel extends ParkourPanelBase
   {
      
      private static const PreNameOfmcSignUp:String = "mcSingUp_";
      
      public function ParkourDailySignUpPanel()
      {
         super(ParkourResConfig.DailySignUpPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
         var _loc3_:Boolean = false;
         var _loc4_:MovieClip = null;
         var _loc1_:int = ParkourUserData.instance.singUpData.todaySignIndex;
         var _loc2_:int = 0;
         while(_loc2_ < ParkourConfig.TotalSignUpDay)
         {
            _loc3_ = ParkourUserData.instance.singUpData.checkSignUpByIndex(_loc2_);
            _loc4_ = panel.getChildByName(PreNameOfmcSignUp + _loc2_) as MovieClip;
            if(ParkourUserData.instance.singUpData.checkSignUpByIndex(_loc2_))
            {
               _loc4_.gotoAndStop(3);
            }
            else if(_loc2_ > _loc1_)
            {
               _loc4_.gotoAndStop(2);
            }
            else if(_loc2_ == _loc1_)
            {
               _loc4_.gotoAndStop(1);
            }
            else
            {
               _loc4_.gotoAndStop(4);
            }
            _loc2_++;
         }
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         var _loc2_:int = 0;
         if(param1 == "btnSignUp")
         {
            _loc2_ = ParkourUserData.instance.singUpData.todaySignIndex;
            ProgressFullSprite.show();
            SocketClient.instance.addEventListener(ParkourClient.CmdDailySign,this.onCmdDailySignUp);
            ParkourClient.dailySign(_loc2_);
         }
      }
      
      private function onCmdDailySignUp(param1:SocketClientEvent) : void
      {
         var bn:Array;
         var gBn:Array = null;
         var evt:SocketClientEvent = param1;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdDailySign,this.onCmdDailySignUp);
         close();
         ParkourUserData.instance.singUpData.signUpToday();
         bn = evt.params.bn;
         gBn = evt.params.gBn;
         ShowBonusHelper.showBonus(bn,function():void
         {
            ParkourHelper.showGBn(gBn);
         });
      }
      
      override protected function onDispose() : void
      {
      }
   }
}

