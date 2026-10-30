package mmo.shoot.players.effects
{
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class FreezeEffect extends PlayerEffectBase
   {
      
      private var freezeTimer:Timer;
      
      public function FreezeEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setFreeze(true);
      }
      
      private function setFreeze(param1:Boolean) : void
      {
         if(this.isMe())
         {
            if(param1)
            {
               this.player.setStrategy(null);
            }
            else
            {
               this.player.setStrategy(new MouseControlStrategy());
            }
            this.freezeTimer = new Timer(2000,1);
            this.freezeTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
            this.freezeTimer.start();
         }
      }
      
      private function onTimerComplete(param1:TimerEvent) : void
      {
         this.stopTimer();
      }
      
      private function stopTimer() : void
      {
         if(this.freezeTimer != null)
         {
            this.freezeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
            this.freezeTimer.stop();
            this.setFreeze(false);
            this.freezeTimer = null;
         }
      }
      
      private function isMe() : Boolean
      {
         return this.player == PlayerManager.getInstance().myPlayer;
      }
      
      override public function get excludeKey() : String
      {
         return "FreezeEffect";
      }
      
      override public function clear() : void
      {
         this.stopTimer();
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

