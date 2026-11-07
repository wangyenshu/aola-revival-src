package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;

   /**
    * The main panel: 狼王再现, 夜王回归 and 终极试炼. In the surviving copy (2016) the state
    * reply only sends one on to the 夜王 panel; here (RECONSTRUCTED from the panel's art) the
    * reply marks each king got (已获得: got1 狼王, got0 夜王, as the king panels read them) and
    * the 终极试炼 won (已战胜), and opens the 终极试炼 once both kings are got ("只有获得了狼王
    * 和夜王的小奥拉才能开启终极试炼!"). The 免费坐骑体验 button (btnOpen) belongs to July 2013.
    */
   public class WNKingChallengeMainPanel extends WNKingPanelBase
   {
      public var btnClose:SimpleButton;
      public var spFinal:MovieClip;
      public var btnChallenge:SimpleButton;
      public var spKing0:MovieClip;
      public var btnKing0:SimpleButton;
      public var spKing1:MovieClip;
      public var btnKing1:SimpleButton;
      public var btnOpen:SimpleButton;

      private var canFinal:Boolean = false;

      public function WNKingChallengeMainPanel()
      {
         super();
         this.getState();
      }

      private function getState():void
      {
         this.visible = false;
         SocketClient.instance.addEventListener("nwk0219-1", this.onState);
         SocketClient.instance.sendXtMessage("HolidayExtension", "nwk0219-1", {});
      }

      private function onState(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener("nwk0219-1", this.onState);
         this.visible = true;
         var wolf:Boolean = Boolean(e.params.got1);
         var night:Boolean = Boolean(e.params.got0);
         if (this.spKing0) this.spKing0.visible = wolf;
         if (this.spKing1) this.spKing1.visible = night;
         if (this.spFinal) this.spFinal.visible = Boolean(e.params.won);
         if (this.btnOpen) this.btnOpen.visible = false;
         this.canFinal = wolf && night;
         if (this.btnChallenge && !this.canFinal)
         {
            DisplayUtil.applyGray(this.btnChallenge);
            TipsManager.getInstance().addTips(this.btnChallenge, "只有获得了狼王和夜王的小奥拉才能开启终极试炼!");
         }
      }

      override protected function clickBtn(evt:MouseEvent):void
      {
         var name:String = evt.target.name as String;
         if (name == "btnClose")
         {
            this.closePanel();
         }
         else if (name == "btnChallenge" && this.canFinal)
         {
            this.closePanel();
            new WNKingFinalChallengePanel().showPanel();
         }
         else if (name != null && name.indexOf("btnKing") == 0)
         {
            this.closePanel();
            new WNKingChallengePanel(parseInt(name.substr(7)), false).showPanel();
         }
      }

      override protected function closePanel():void
      {
         if (this.btnChallenge) TipsManager.getInstance().removeTips(this.btnChallenge);
         super.closePanel();
      }

      override public function showPanel():void
      {
         super.showPanel();
         SundriesClient.logEvent(4144);
      }
   }
}
