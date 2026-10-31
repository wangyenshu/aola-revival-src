package mmo.game.parkour.game.data.mapitem
{
   public class ParkourBarrierInfo extends ParkourMapItemInfo
   {
      
      private var _canDestroy:Boolean;
      
      public function ParkourBarrierInfo(param1:int, param2:int, param3:Boolean)
      {
         super(param1,param2);
         this._canDestroy = param3;
      }
      
      public function get canDestroy() : Boolean
      {
         return this._canDestroy;
      }
   }
}

