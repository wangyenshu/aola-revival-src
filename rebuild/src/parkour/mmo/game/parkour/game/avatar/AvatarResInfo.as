package mmo.game.parkour.game.avatar
{
   public class AvatarResInfo
   {
      
      private var _roleId:int;
      
      private var _rideId:int;
      
      public function AvatarResInfo(param1:int, param2:int)
      {
         super();
         this._roleId = param1;
         this._rideId = param2;
      }
      
      public function get roldId() : int
      {
         return this._roleId;
      }
      
      public function get rideId() : int
      {
         return this._rideId;
      }
   }
}

