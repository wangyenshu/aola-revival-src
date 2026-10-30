package mmo.shoot
{
   import mmo.interfaces.IDispose;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class ShootForPlayer implements IShootEffectTarget, IDispose
   {
      
      private var player:PlayerBase;
      
      public function ShootForPlayer(param1:PlayerBase)
      {
         super();
         this.player = param1;
      }
      
      public function get x() : Number
      {
         return this.player.x;
      }
      
      public function get y() : Number
      {
         return this.player.y - 48;
      }
      
      public function dispose() : void
      {
         this.player = null;
      }
   }
}

