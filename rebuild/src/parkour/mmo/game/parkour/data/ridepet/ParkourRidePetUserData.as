package mmo.game.parkour.data.ridepet
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.config.ParkourRidePetConfig;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRidePetUserData
   {
      
      private var _exp:ConfuseInteger = new ConfuseInteger();
      
      private var _level:ConfuseInteger = new ConfuseInteger(1);
      
      private var _info:ParkourRidePetInfo;
      
      public function ParkourRidePetUserData(param1:ParkourRidePetInfo)
      {
         super();
         this._info = param1;
      }
      
      public static function createByParams(param1:Object) : ParkourRidePetUserData
      {
         var _loc2_:int = int(param1.rId);
         var _loc3_:ParkourRidePetInfo = ParkourRidePetConfig.getRidePetInfoById(_loc2_);
         var _loc4_:ParkourRidePetUserData = new ParkourRidePetUserData(_loc3_);
         _loc4_.level = param1.lv;
         _loc4_.exp = param1.ce;
         return _loc4_;
      }
      
      public function get info() : ParkourRidePetInfo
      {
         return this._info;
      }
      
      public function get level() : int
      {
         return this._level.getValue();
      }
      
      public function set level(param1:int) : void
      {
         this._level.setValue(param1);
      }
      
      public function get nextLvNeedExp() : int
      {
         var _loc1_:int = Math.min(40,this.level);
         return _loc1_ * 1000;
      }
      
      public function get nextLvNeedMoney() : int
      {
         var _loc1_:int = Math.min(40,this.level);
         return _loc1_ * 100;
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
      
      public function get flyCoinPercent() : Number
      {
         return ParkourHelper.formatNumber(this.info.baseAbility.flyCoinPercent + int(this.level / 4) * this.info.upAbility.flyCoinPercent);
      }
      
      public function get absoreTimeMillSec() : int
      {
         return this.info.baseAbility.absoreTimeMillSec + int((this.level + 1) / 4) * this.info.upAbility.absoreTimeMillSec;
      }
      
      public function get invincibleTimeMillSec() : int
      {
         return this.info.baseAbility.invincibleTimeMillSec + int((this.level - 1) / 4) * this.info.upAbility.invincibleTimeMillSec;
      }
      
      public function get scorePercent() : int
      {
         return this.info.baseAbility.scorePercent + this.upLevel * this.info.upAbility.scorePercent;
      }
      
      public function get moneyPercent() : int
      {
         return this.info.baseAbility.moneyPercent + this.upLevel * this.info.upAbility.moneyPercent;
      }
      
      private function get upLevel() : int
      {
         return this.level - 1;
      }
      
      public function createDataByLevel(param1:int) : ParkourRidePetUserData
      {
         var _loc2_:ParkourRidePetUserData = new ParkourRidePetUserData(this.info);
         _loc2_.level = param1;
         return _loc2_;
      }
      
      public function get exp() : int
      {
         return this._exp.getValue();
      }
      
      public function set exp(param1:int) : void
      {
         this._exp.setValue(param1);
      }
   }
}

