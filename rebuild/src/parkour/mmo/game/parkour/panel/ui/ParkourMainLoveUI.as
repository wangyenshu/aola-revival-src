package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mmo.common.utils.tips.TipsManager;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.play.activity.helper.TimeText_Helper;
   
   public class ParkourMainLoveUI
   {
      
      private var container:MovieClip;
      
      private var timer:Timer = new Timer(1000);
      
      public function ParkourMainLoveUI(param1:MovieClip)
      {
         super();
         this.container = param1;
         this.timer.addEventListener(TimerEvent.TIMER,this.onTimer);
      }
      
      public function onInit() : void
      {
         this.checkTimer();
      }
      
      private function onTimer(param1:TimerEvent) : void
      {
         --ParkourUserData.instance.nextLoveCD;
         if(ParkourUserData.instance.nextLoveCD <= 0)
         {
            ++ParkourUserData.instance.myLove;
            if(ParkourUserData.instance.myLove < ParkourConfig.MaxLove)
            {
               ParkourUserData.instance.nextLoveCD = ParkourConfig.DefaultAddLoveDelay;
            }
            else
            {
               ParkourUserData.instance.nextLoveCD = 0;
            }
         }
         this.refreshCd();
         this.checkTimer();
      }
      
      private function checkTimer() : void
      {
         if(ParkourUserData.instance.nextLoveCD <= 0)
         {
            this.timer.stop();
         }
         else
         {
            this.timer.start();
         }
      }
      
      private function refreshCd() : void
      {
         var _loc2_:int = 0;
         var _loc1_:TextField = this.container.txtCD as TextField;
         if(ParkourUserData.instance.myLove == ParkourConfig.MaxLove)
         {
            _loc1_.text = "Max";
         }
         else if(ParkourUserData.instance.myLove > ParkourConfig.MaxLove)
         {
            _loc2_ = ParkourUserData.instance.myLove - ParkourConfig.MaxLove;
            _loc1_.text = "+" + _loc2_;
         }
         else
         {
            TimeText_Helper.setShortTime(_loc1_,ParkourUserData.instance.nextLoveCD);
         }
      }
      
      public function refresh() : void
      {
         var _loc2_:MovieClip = null;
         this.refreshCd();
         var _loc1_:int = 0;
         while(_loc1_ < ParkourConfig.MaxLove)
         {
            _loc2_ = this.container.getChildByName("mcLove" + _loc1_) as MovieClip;
            _loc2_.visible = _loc1_ < ParkourUserData.instance.myLove;
            TipsManager.getInstance().addTips(_loc2_,"每次酷跑消耗1个");
            _loc1_++;
         }
      }
      
      public function dispose() : void
      {
         this.timer.removeEventListener(TimerEvent.TIMER,this.onTimer);
         this.timer.stop();
         this.timer = null;
      }
   }
}

