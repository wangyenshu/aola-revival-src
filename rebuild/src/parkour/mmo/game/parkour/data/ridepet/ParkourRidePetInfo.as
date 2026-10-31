package mmo.game.parkour.data.ridepet
{
   public class ParkourRidePetInfo
   {
      
      private var _type:int;
      
      private var _baseAbility:ParkourRidePetAbility = new ParkourRidePetAbility(1,1,1,1,1,1);
      
      private var _upAbility:ParkourRidePetAbility = new ParkourRidePetAbility(1,1,1,1,1,1);
      
      private var _effectTip:String;
      
      private var _effectClass:Class;
      
      private var _effectParams:Object;
      
      private var _price:int;
      
      public function ParkourRidePetInfo(param1:int, param2:int, param3:ParkourRidePetAbility, param4:ParkourRidePetAbility, param5:String, param6:Class, param7:Object = null)
      {
         super();
         this._type = param1;
         this._price = param2;
         this._baseAbility = param3;
         this._upAbility = param4;
         this._effectTip = param5;
         this._effectClass = param6;
         this._effectParams = param7;
      }
      
      public function get effectParams() : Object
      {
         return this._effectParams;
      }
      
      public function get effectClass() : Class
      {
         return this._effectClass;
      }
      
      public function get id() : int
      {
         return this._type;
      }
      
      public function get baseAbility() : ParkourRidePetAbility
      {
         return this._baseAbility;
      }
      
      public function get upAbility() : ParkourRidePetAbility
      {
         return this._upAbility;
      }
      
      public function get price() : int
      {
         return this._price;
      }
      
      public function get effectTip() : String
      {
         return this._effectTip;
      }
   }
}

