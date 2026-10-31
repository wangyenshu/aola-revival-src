package mmo.game.parkour.data.role
{
   import mmo.common.datastructure.ConfuseInteger;
   
   public class ParkourRoleInfo
   {
      
      private var _id:ConfuseInteger = new ConfuseInteger();
      
      private var _baseAbility:ParkourRoleAbility = new ParkourRoleAbility(1,1,1,1,1);
      
      private var _upAblility:ParkourRoleAbility = new ParkourRoleAbility(1,1,1,1,1);
      
      private var _price:int;
      
      private var _skillName:String;
      
      private var _skillTip:String;
      
      private var _skillTime:int;
      
      private var _skillClass:Class;
      
      private var _skillparams:Object;
      
      private var _name:String;
      
      public function ParkourRoleInfo(param1:int, param2:String, param3:int, param4:String, param5:String, param6:int, param7:Class, param8:Object, param9:ParkourRoleAbility, param10:ParkourRoleAbility)
      {
         super();
         this._id.setValue(param1);
         this._price = param3;
         this._name = param2;
         this._skillName = param4;
         this._skillTip = param5;
         this._baseAbility = param9;
         this._upAblility = param10;
         this._skillTime = param6;
         this._skillClass = param7;
         this._skillparams = param8;
      }
      
      public function get id() : int
      {
         return this._id.getValue();
      }
      
      public function get baseAbility() : ParkourRoleAbility
      {
         return this._baseAbility;
      }
      
      public function get upAbility() : ParkourRoleAbility
      {
         return this._upAblility;
      }
      
      public function get price() : int
      {
         return this._price;
      }
      
      public function get skillClass() : Class
      {
         return this._skillClass;
      }
      
      public function get skillparams() : Object
      {
         return this._skillparams;
      }
      
      public function get skillTime() : int
      {
         return this._skillTime;
      }
      
      public function get skillTip() : String
      {
         return this._skillTip;
      }
      
      public function get name() : String
      {
         return this._name;
      }
      
      public function get skillName() : String
      {
         return this._skillName;
      }
   }
}

