package mmo.game.parkour.data.role
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.config.ParkourRoleConfig;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRoleUserData
   {
      
      private var _level:ConfuseInteger = new ConfuseInteger(1);
      
      private var _totalExp:ConfuseInteger = new ConfuseInteger(0);
      
      private var info:ParkourRoleInfo;
      
      private var _isExit:Boolean = false;
      
      public function ParkourRoleUserData(param1:ParkourRoleInfo)
      {
         super();
         this.info = param1;
      }
      
      public static function createByIdAndIsExit(param1:int, param2:Boolean) : ParkourRoleUserData
      {
         var _loc3_:ParkourRoleInfo = ParkourRoleConfig.getRoleInfoById(param1);
         var _loc4_:ParkourRoleUserData = new ParkourRoleUserData(_loc3_);
         _loc4_.level = 1;
         _loc4_.totalExp = 0;
         _loc4_.isExit = param2;
         return _loc4_;
      }
      
      public function getInfo() : ParkourRoleInfo
      {
         return this.info;
      }
      
      public function get level() : int
      {
         return this._level.getValue();
      }
      
      public function set level(param1:int) : void
      {
         this._level.setValue(param1);
      }
      
      public function get exp() : int
      {
         var _loc1_:int = this.getNeedExpFormBorn(this.level);
         return this.totalExp - _loc1_;
      }
      
      private function getNeedExpFormBorn(param1:int) : int
      {
         var _loc2_:int = 0;
         var _loc3_:int = 1;
         while(_loc3_ < param1)
         {
            _loc2_ += this.getUpLevelNeedExp(_loc3_);
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function get totalExp() : int
      {
         return this._totalExp.getValue();
      }
      
      public function set totalExp(param1:int) : void
      {
         this._totalExp.setValue(param1);
      }
      
      public function get nextLvNeedExp() : int
      {
         return this.getUpLevelNeedExp(this.level);
      }
      
      public function get nextLvNeedMoney() : int
      {
         var _loc1_:int = Math.min(40,this.level);
         return _loc1_ * 100;
      }
      
      private function getUpLevelNeedExp(param1:int) : int
      {
         var _loc2_:int = Math.min(40,param1);
         return _loc2_ * 1000;
      }
      
      public function get id() : int
      {
         return this.info.id;
      }
      
      public function get flyTimeSec() : Number
      {
         return ParkourHelper.formatNumber(this.flyTimeMillSec / 1000);
      }
      
      public function get absoreTimeSec() : Number
      {
         return ParkourHelper.formatNumber(this.absoreTimeMillSec / 1000);
      }
      
      public function get invincibleTimeSec() : Number
      {
         return ParkourHelper.formatNumber(this.invincibleTimeMillSec / 1000);
      }
      
      public function get flyTimeMillSec() : int
      {
         return this.info.baseAbility.flyTimeMillSec + int((this.level + 2) / 4) * this.info.upAbility.flyTimeMillSec;
      }
      
      public function get absoreTimeMillSec() : int
      {
         return this.info.baseAbility.absoreTimeMillSec + int((this.level + 1) / 4) * this.info.upAbility.absoreTimeMillSec;
      }
      
      public function get flyCoinPercent() : Number
      {
         return this.info.baseAbility.flyCoinPercent + int(this.level / 4) * this.info.upAbility.flyCoinPercent;
      }
      
      public function get invincibleTimeMillSec() : int
      {
         return this.info.baseAbility.invincibleTimeMillSec + int((this.level - 1) / 4) * this.info.upAbility.invincibleTimeMillSec;
      }
      
      public function get superCool() : Number
      {
         return this.info.baseAbility.superCool + this.upLevel * this.info.upAbility.superCool;
      }
      
      private function get upLevel() : int
      {
         return this.level - 1;
      }
      
      public function get skillExcuteTime() : int
      {
         return this.info.skillTime;
      }
      
      public function get skillClass() : Class
      {
         return this.info.skillClass;
      }
      
      public function get skillparams() : Object
      {
         return this.info.skillparams;
      }
      
      public function cloneDataByLevel(param1:int) : ParkourRoleUserData
      {
         var _loc2_:ParkourRoleUserData = new ParkourRoleUserData(this.info);
         _loc2_.level = param1;
         _loc2_.totalExp = this.getNeedExpFormBorn(param1);
         _loc2_.isExit = this.isExit;
         return _loc2_;
      }
      
      public function get isExit() : Boolean
      {
         return this._isExit;
      }
      
      public function set isExit(param1:Boolean) : void
      {
         this._isExit = param1;
      }
   }
}

