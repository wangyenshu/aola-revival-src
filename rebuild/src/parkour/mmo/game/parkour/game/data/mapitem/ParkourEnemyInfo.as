package mmo.game.parkour.game.data.mapitem
{
   public class ParkourEnemyInfo extends ParkourMapItemInfo
   {
      
      private var _canDestroy:Boolean;
      
      private var _moveClass:Class = null;
      
      public function ParkourEnemyInfo(param1:int, param2:int, param3:Boolean, param4:Class = null)
      {
         super(param1,param2);
         this._moveClass = param4;
         this._canDestroy = param3;
      }
      
      public function get canDestroy() : Boolean
      {
         return this._canDestroy;
      }
      
      public function get moveClass() : Class
      {
         return this._moveClass;
      }
   }
}

