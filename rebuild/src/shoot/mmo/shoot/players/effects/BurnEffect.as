package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.events.TimerEvent;
   import flash.filters.ColorMatrixFilter;
   import flash.utils.Timer;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class BurnEffect extends PlayerEffectBase
   {
      
      private var burnTimer:Timer;
      
      public function BurnEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setBurn(true);
      }
      
      private function setBurn(param1:Boolean) : void
      {
         this.setBurnEffect(param1);
      }
      
      private function setBurnEffect(param1:Boolean) : void
      {
         var _loc3_:Array = null;
         var _loc2_:DisplayObject = Player(this.player).dressily.avatarSprite as DisplayObject;
         if(param1)
         {
            _loc3_ = new Array();
            _loc3_ = _loc3_.concat([0.0317,0.0703,0.09,0,0]);
            _loc3_ = _loc3_.concat([0.0307,0.03753,0.09,0,0]);
            _loc3_ = _loc3_.concat([0.0307,0.0703,0.0589,0,0]);
            _loc3_ = _loc3_.concat([0,0,0,0.8,0]);
            this.applyFilter(_loc2_,_loc3_);
         }
         else
         {
            _loc2_.filters = null;
         }
      }
      
      private function applyFilter(param1:DisplayObject, param2:Array) : void
      {
         var _loc3_:ColorMatrixFilter = new ColorMatrixFilter(param2);
         var _loc4_:Array = new Array();
         _loc4_.push(_loc3_);
         param1.filters = _loc4_;
      }
      
      private function onTimerComplete(param1:TimerEvent) : void
      {
         this.stopTimer();
      }
      
      private function stopTimer() : void
      {
         if(this.burnTimer != null)
         {
            this.burnTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
            this.burnTimer.stop();
            this.setBurn(false);
            this.burnTimer = null;
         }
      }
      
      private function isMe() : Boolean
      {
         return this.player == PlayerManager.getInstance().myPlayer;
      }
      
      override public function get excludeKey() : String
      {
         return "BurnEffect";
      }
      
      override public function clear() : void
      {
         this.setBurn(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

