package mmo.fbteam.dataobject
{
   import flash.geom.Point;
   
   public class FBPetInfo
   {
      
      private var _raceId:int = -1;
      
      private var _id:int = -1;
      
      private var _lv:int = -1;
      
      private var _point:Point = null;
      
      public function FBPetInfo(param1:int, param2:int, param3:int, param4:Point)
      {
         super();
         this._raceId = param1;
         this._id = param2;
         this._lv = param3;
         this._point = param4;
      }
      
      public function get raceId() : int
      {
         return this._raceId;
      }
      
      public function get id() : int
      {
         return this._id;
      }
      
      public function get lv() : int
      {
         return this._lv;
      }
      
      public function get point() : Point
      {
         return this._point;
      }
      
      public function equals(param1:FBPetInfo) : Boolean
      {
         if(null == param1)
         {
            return false;
         }
         if(param1 == this)
         {
            return true;
         }
         if(param1.raceId == this._raceId && param1.id == this._id && param1.lv == this._lv)
         {
            return true;
         }
         return false;
      }
      
      public function isSamePet(param1:int, param2:int) : Boolean
      {
         if(this._raceId == param1 && this._id == param2)
         {
            return true;
         }
         return false;
      }
      
      public function toString() : String
      {
         return "[object FBPetInfo(" + this.raceId + "|" + this.id + "|" + this.lv + "|" + this.point + ")]";
      }
   }
}

