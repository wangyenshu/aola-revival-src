package mmo.game.parkour.game.mapitem.move
{
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.interfaces.IParkourMapItemMoveStrategy;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.player.ParkourPlayer;
   
   public class ParkourMoveToPlayerStrategy implements IParkourMapItemMoveStrategy
   {
      
      private var item:ParkourAbstractMapItem;
      
      public function ParkourMoveToPlayerStrategy()
      {
         super();
      }
      
      public function setControlItem(param1:ParkourAbstractMapItem) : void
      {
         this.item = param1;
      }
      
      public function move(param1:int) : void
      {
         var _loc2_:ParkourPlayer = ParkourGameScene.instance.getPlayer();
         var _loc3_:Number = _loc2_.x;
         var _loc4_:Number = _loc2_.y - _loc2_.view.height / 2;
         var _loc5_:Number = (_loc3_ - this.item.x) / 5;
         var _loc6_:Number = (_loc4_ - this.item.y) / 5;
         this.item.x += _loc5_;
         this.item.y += _loc6_;
      }
      
      public function dispose() : void
      {
         this.item = null;
      }
   }
}

