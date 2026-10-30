package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class DecelerateEffect extends PlayerEffectBase
   {
      
      private var walkSpeed:int;
      
      public function DecelerateEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
         // The 2013 PlayerBase has a walk speed, not the later speed scale.
         this.walkSpeed = this.player.walkSpeed;
      }
      
      override public function apply() : void
      {
         this.setDecelerate(true);
      }
      
      private function setDecelerate(param1:Boolean) : void
      {
         this.player.walkSpeed = param1 ? Math.max(1,this.walkSpeed / 2) : this.walkSpeed;
      }
      
      override public function get excludeKey() : String
      {
         return "DecelerateEffect";
      }
      
      override public function clear() : void
      {
         this.setDecelerate(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

