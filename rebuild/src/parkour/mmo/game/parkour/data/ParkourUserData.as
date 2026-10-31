package mmo.game.parkour.data
{
   import flash.events.Event;
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.common.event.BtEventDispatcher;
   import mmo.common.parse.Parse;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourRidePetConfig;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.data.signup.ParkourDailySignUpData;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourUserData extends BtEventDispatcher
   {
      
      private static var _instance:ParkourUserData;
      
      public static const OnDataUpdate:String = "OnDataUpdate";
      
      private var _myMoney:ConfuseInteger = new ConfuseInteger();
      
      private var _myLove:ConfuseInteger = new ConfuseInteger();
      
      private var _nextLoveDelay:ConfuseInteger = new ConfuseInteger();
      
      private var _totalRunDistance:ConfuseInteger = new ConfuseInteger();
      
      private var _rewardNum:ConfuseInteger = new ConfuseInteger();
      
      private var _myRank:int;
      
      private var _myHightestDistance:int;
      
      private var selectedRoleId:int = 1;
      
      private var selectedRidePetId:int = 1;
      
      private var roleDataMap:Object = {};
      
      private var ridePetDataMap:Object = {};
      
      private var _isFirst:Boolean;
      
      private var _singUpData:ParkourDailySignUpData;
      
      private var _numOfUnGetTask:int = 5;
      
      private var _usedField:int = 0;
      
      private var _rentingRoleIds:Array = [];
      
      private var _lfetTimesOfRentRole:int = 0;
      
      public function ParkourUserData()
      {
         super();
         var _loc1_:ParkourRoleUserData = ParkourRoleUserData.createByIdAndIsExit(1,true);
         var _loc2_:ParkourRidePetUserData = new ParkourRidePetUserData(ParkourRidePetConfig.getRidePetInfoById(1));
         this._singUpData = new ParkourDailySignUpData();
         this.repaceIntoRidePet(_loc2_);
         this.repaceIntoRole(_loc1_);
      }
      
      public static function get instance() : ParkourUserData
      {
         if(_instance == null)
         {
            _instance = new ParkourUserData();
         }
         return _instance;
      }
      
      public function parseParams(param1:Object) : void
      {
         this._isFirst = param1.fr;
         this.myLove = param1.e;
         this.nextLoveCD = param1.cd;
         this.myMoney = param1.j;
         this._totalRunDistance.setValue(param1.d);
         this._myRank = param1.mr;
         this._myHightestDistance = param1.ml;
         this._rewardNum.setValue(param1.gc);
         this.singUpData.parseFlag(param1.df);
         this.roleDataMap = ParkourHelper.parseRoleDataMap(param1.pl);
         this.ridePetDataMap = ParkourHelper.parseRidePetDataMap(param1.rl);
         this.parseRentingRole(param1.rents);
         var _loc2_:int = int(param1.rt);
         var _loc3_:Array = Parse.parseIntToArray(param1.ts,10);
         this._numOfUnGetTask = ParkourConfig.NunmOfNeedDoTaskPerDay;
         var _loc4_:int = 0;
         while(_loc4_ < ParkourConfig.NunmOfNeedDoTaskPerDay - 1)
         {
            if(_loc3_[_loc4_])
            {
               --this._numOfUnGetTask;
            }
            _loc4_++;
         }
         if(_loc3_[_loc2_])
         {
            --this._numOfUnGetTask;
         }
         this.checkInitSelectRoleAndPetRideAndMap();
      }
      
      private function checkInitSelectRoleAndPetRideAndMap() : void
      {
         var _loc1_:int = LocalStore.getValue(ParkourConfig.LocalKeyOfSelectRole,UserInfo.userName) as int;
         var _loc2_:int = LocalStore.getValue(ParkourConfig.LocalKeyOfSelectRide,UserInfo.userName) as int;
         var _loc3_:int = LocalStore.getValue(ParkourConfig.LocalKeyOfSelectMap,UserInfo.userName) as int;
         _loc1_ = _loc1_ <= 0 ? 1 : _loc1_;
         _loc2_ = _loc1_ <= 0 ? 1 : _loc2_;
         this.changeSelectedRole(_loc1_);
         this.changeSelectedRidePet(_loc2_);
         this.usedField = _loc3_;
      }
      
      public function parseRentingRole(param1:String) : void
      {
         var _loc3_:String = null;
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:Boolean = false;
         this._rentingRoleIds = [];
         this._lfetTimesOfRentRole = ParkourConfig.MaxTimesOfRentRole;
         if(param1 == null || param1 == "")
         {
            return;
         }
         var _loc2_:Array = param1.split(";");
         this._lfetTimesOfRentRole -= _loc2_.length;
         for each(_loc3_ in _loc2_)
         {
            _loc4_ = _loc3_.split(":");
            _loc5_ = int(_loc4_[0]);
            _loc6_ = _loc4_[1] == 1;
            if(!_loc6_)
            {
               this._rentingRoleIds.push(_loc5_);
            }
         }
      }
      
      public function get myLove() : int
      {
         return this._myLove.getValue();
      }
      
      public function set myLove(param1:int) : void
      {
         this._myLove.setValue(param1);
         this.notifyUpdate();
      }
      
      public function onTaskDone() : void
      {
         --this._numOfUnGetTask;
      }
      
      public function getSelectedRoleData() : ParkourRoleUserData
      {
         if(this.selectedRoleId < 0)
         {
            return null;
         }
         return this.getRoleData(this.selectedRoleId);
      }
      
      public function repaceIntoRole(param1:ParkourRoleUserData) : void
      {
         this.roleDataMap[param1.id] = param1;
         this.notifyUpdate();
      }
      
      public function getRoleData(param1:int) : ParkourRoleUserData
      {
         return this.roleDataMap[param1] as ParkourRoleUserData;
      }
      
      public function changeSelectedRole(param1:int) : Boolean
      {
         if(this.getRoleData(param1) == null)
         {
            return false;
         }
         this.selectedRoleId = param1;
         LocalStore.setValue(ParkourConfig.LocalKeyOfSelectRole,this.selectedRoleId,UserInfo.userName);
         this.notifyUpdate();
         return true;
      }
      
      public function getSelectedRidePetData() : ParkourRidePetUserData
      {
         return this.getRidePetData(this.selectedRidePetId);
      }
      
      public function changeSelectedRidePet(param1:int) : Boolean
      {
         if(this.getRidePetData(param1) == null)
         {
            return false;
         }
         this.selectedRidePetId = param1;
         LocalStore.setValue(ParkourConfig.LocalKeyOfSelectRide,this.selectedRidePetId,UserInfo.userName);
         this.notifyUpdate();
         return true;
      }
      
      public function repaceIntoRidePet(param1:ParkourRidePetUserData) : void
      {
         this.ridePetDataMap[param1.info.id] = param1;
         this.notifyUpdate();
      }
      
      public function getRidePetData(param1:int) : ParkourRidePetUserData
      {
         return this.ridePetDataMap[param1] as ParkourRidePetUserData;
      }
      
      public function get myMoney() : int
      {
         return this._myMoney.getValue();
      }
      
      public function set myMoney(param1:int) : void
      {
         this._myMoney.setValue(param1);
         this.notifyUpdate();
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
      
      public function get nextLoveCD() : int
      {
         return this._nextLoveDelay.getValue();
      }
      
      public function set nextLoveCD(param1:int) : void
      {
         this._nextLoveDelay.setValue(param1);
         this.notifyUpdate();
      }
      
      public function get totalRunDistance() : int
      {
         return this._totalRunDistance.getValue();
      }
      
      public function get myHightestDistance() : int
      {
         return this._myHightestDistance;
      }
      
      public function get myRank() : int
      {
         return this._myRank;
      }
      
      private function notifyUpdate() : void
      {
         dispatchEvent(new Event(OnDataUpdate));
      }
      
      public function get rewardNum() : int
      {
         return this._rewardNum.getValue();
      }
      
      public function set rewardNum(param1:int) : void
      {
         this._rewardNum.setValue(param1);
         this.notifyUpdate();
      }
      
      public function get isFirst() : Boolean
      {
         return this._isFirst;
      }
      
      public function set isFirst(param1:Boolean) : void
      {
         this._isFirst = param1;
      }
      
      public function get singUpData() : ParkourDailySignUpData
      {
         return this._singUpData;
      }
      
      public function get numOfDailyTask() : int
      {
         return this._numOfUnGetTask;
      }
      
      public function get usedField() : int
      {
         return this._usedField;
      }
      
      public function set usedField(param1:int) : void
      {
         this._usedField = param1;
         LocalStore.setValue(ParkourConfig.LocalKeyOfSelectMap,this._usedField,UserInfo.userName);
         this.notifyUpdate();
      }
      
      public function isRentingRole(param1:int) : Boolean
      {
         return this._rentingRoleIds.indexOf(param1) != -1;
      }
      
      public function rentRole(param1:int) : void
      {
         var _loc2_:ParkourRoleUserData = this.getRoleData(param1);
         if(_loc2_ != null)
         {
            if(!_loc2_.isExit)
            {
               this._rentingRoleIds.push(param1);
            }
         }
         this.notifyUpdate();
      }
      
      public function returnRentRole(param1:int) : void
      {
         var _loc2_:int = this._rentingRoleIds.indexOf(param1);
         if(_loc2_ != -1)
         {
            this._rentingRoleIds.splice(_loc2_,1);
         }
         this.notifyUpdate();
      }
      
      public function get lfetTimesOfRentRole() : int
      {
         return this._lfetTimesOfRentRole;
      }
      
      public function set lfetTimesOfRentRole(param1:int) : void
      {
         this._lfetTimesOfRentRole = param1;
         this.notifyUpdate();
      }
   }
}

