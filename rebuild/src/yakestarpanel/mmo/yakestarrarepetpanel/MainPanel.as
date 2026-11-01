package mmo.yakestarrarepetpanel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   public class MainPanel extends Sprite implements IDispose, IShowPanel
   {
      
      private static const totalSecond:int = 10 * 60;
      
      public var btngo:SimpleButton;
      
      public var mcgoing:MovieClip;
      
      public var btnclose:SimpleButton;
      
      public var txttime:TextField;
      
      public var mccan:MovieClip;
      
      public var mcstate:MovieClip;
      
      private var btnClose:SimpleButton = null;
      
      private var btnGo:SimpleButton = null;
      
      private var mcState:MovieClip = null;
      
      private var mcStateMC:MovieClip = null;
      
      private var mcGoing:MovieClip = null;
      
      private var txtTime:TextField = null;
      
      private var mcCan:MovieClip = null;
      
      private var timer:Timer = null;
      
      private var can:Boolean = true;
      
      private var needSecond:int = 0;
      
      private var count:int = 0;
      
      public function MainPanel()
      {
         super();
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         this.btnClose = this.btnclose as SimpleButton;
         this.btnGo = this.btngo as SimpleButton;
         this.mcState = this.mcstate as MovieClip;
         this.mcStateMC = this.mcState.getChildByName("mc") as MovieClip;
         this.mcStateMC.stop();
         this.mcGoing = this.mcgoing as MovieClip;
         this.mcGoing.visible = false;
         this.txtTime = this.txttime as TextField;
         this.mcCan = this.mccan as MovieClip;
         this.timer = new Timer(1000,0);
      }
      
      private function initFuns() : void
      {
         this.btnClose.addEventListener(MouseEvent.CLICK,this.onClose);
         this.btnGo.addEventListener(MouseEvent.CLICK,this.onGo);
         this.btnGo.mouseEnabled = false;
         this.timer.addEventListener(TimerEvent.TIMER,this.onTime);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         this.closePanel();
      }
      
      private function onGo(param1:MouseEvent) : void
      {
         this.btnGo.mouseEnabled = false;
         SocketClient.instance.addEventListener(YakestarRarepetClient.cmdLogRarePet,this.onLogReturn);
         YakestarRarepetClient.logRarePet();
      }
      
      private function onTime(param1:TimerEvent) : void
      {
         --this.needSecond;
         this.updateTimeUI(this.needSecond);
         if(this.timer.currentCount == this.timer.repeatCount)
         {
            this.mcGoing.visible = false;
            this.mcState.visible = true;
            this.dealWithPars();
         }
      }
      
      private function onLogReturn(param1:SocketClientEvent) : void
      {
         var succ:Boolean;
         var mc:MovieClip = null;
         var e:SocketClientEvent = param1;
         SocketClient.instance.removeEventListener(YakestarRarepetClient.cmdLogRarePet,this.onLogReturn);
         succ = Boolean(e.params.succ);
         ++this.count;
         this.mcGoing.gotoAndStop(this.count + 1);
         this.count = this.count >= 5 ? int(this.count - 5) : this.count;
         this.needSecond = totalSecond;
         this.mcState.visible = this.count == 0;
         this.mcGoing.visible = true;
         this.dealWithPars();
         if(succ)
         {
            // aola-revival: the later ProgressFullSprite.lockScreen is not in the 2013 library.
            mc = this.mcGoing.numChildren > 0 ? this.mcGoing.getChildAt(0) as MovieClip : null;
            // aola-revival: without its animation (or with a single frame) the screen is not locked.
            if (mc == null || mc.totalFrames < 2)
            {
               closePanel();
               new GettedPanel().showPanel();
               return;
            }
            ProgressFullSprite.show();
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               ProgressFullSprite.close();
               mc.stop();
               closePanel();
               new GettedPanel().showPanel();
            });
         }
      }
      
      private function getServerState() : void
      {
         SocketClient.instance.addEventListener(YakestarRarepetClient.cmdGetRarePetTime,this.onGetServerState);
         YakestarRarepetClient.getRarePetTime();
      }
      
      private function onGetServerState(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(YakestarRarepetClient.cmdGetRarePetTime,this.onGetServerState);
         this.can = true;
         this.count = param1.params.c;
         this.count %= 5;
         var _loc2_:int = int(param1.params.t);
         this.needSecond = 0 == _loc2_ ? 0 : int(_loc2_ / 1000);
         this.needSecond = totalSecond < this.needSecond ? totalSecond : this.needSecond;
         ProgressFullSprite.close();
         ModalDialogManager.getInstance().addModalDialog(this,AlignType.NONE,0,true,0,0,true);
         this.mcState.visible = true;
         this.mcGoing.visible = false;
         this.dealWithPars();
      }
      
      private function dealWithPars() : void
      {
         if(this.can)
         {
            this.mcCan.gotoAndStop(1);
            this.mcState.gotoAndStop(this.count + 1);
            if(this.needSecond == 0)
            {
               this.updateTimeUI(0);
               this.btnGo.mouseEnabled = true;
               this.mcStateMC.play();
            }
            else
            {
               this.btnGo.mouseEnabled = false;
               this.updateTimeUI(this.needSecond);
               this.updateTime(this.needSecond);
            }
         }
         else
         {
            this.mcCan.gotoAndStop(2);
            this.mcState.gotoAndStop(6);
            DisplayUtil.stopAndRemove(this.txtTime);
            DisplayUtil.stopAndRemove(this.btnGo);
         }
      }
      
      private function updateTime(param1:int) : void
      {
         this.timer.reset();
         this.timer.repeatCount = param1;
         this.timer.start();
      }
      
      private function updateTimeUI(param1:int) : void
      {
         var _loc2_:int = param1 / 60;
         var _loc3_:int = param1 % 60;
         var _loc4_:String = _loc2_ > 9 ? "" + _loc2_ : "0" + _loc2_;
         var _loc5_:String = _loc3_ > 9 ? "" + _loc3_ : "0" + _loc3_;
         this.txtTime.text = _loc4_ + ":" + _loc5_;
      }
      
      private function closePanel() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function disposeEvents() : void
      {
         this.timer.stop();
         this.timer.removeEventListener(TimerEvent.TIMER,this.onTime);
         SocketClient.instance.removeEventListener(YakestarRarepetClient.cmdLogRarePet,this.onLogReturn);
         SocketClient.instance.removeEventListener(YakestarRarepetClient.cmdGetRarePetTime,this.onGetServerState);
      }
      
      public function showPanel() : void
      {
         ProgressFullSprite.show();
         this.getServerState();
      }
      
      public function dispose() : void
      {
         this.disposeEvents();
      }
   }
}

