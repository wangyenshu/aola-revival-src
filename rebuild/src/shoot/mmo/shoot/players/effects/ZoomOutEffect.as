package mmo.shoot.players.effects
{
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   
   public class ZoomOutEffect extends PlayerEffectBase
   {
      
      public function ZoomOutEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setZoomOut(true);
      }
      
      public function setZoomOut(param1:Boolean) : void
      {
         var _loc2_:ScenePlayer = this.player as ScenePlayer;
         if(param1)
         {
            _loc2_.scaleX = 0.7;
            _loc2_.scaleY = this.player.scaleX;
         }
         else
         {
            _loc2_.scaleX = 1;
            _loc2_.scaleY = this.player.scaleX;
         }
      }
      
      override public function get excludeKey() : String
      {
         return "ZoomOutEffect";
      }
      
      override public function clear() : void
      {
         this.setZoomOut(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

