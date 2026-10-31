package mmo.game.parkour.game.player
{
   import flash.display.DisplayObject;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleAbility;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.event.ParkourEvent;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.avatar.Avatar;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.interfaces.IParkourPlayerState;
   import mmo.game.parkour.game.interfaces.IParkourRoleSkill;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   import mmo.game.parkour.game.player.state.ParkourPlayerDieState;
   import mmo.game.parkour.game.player.state.ParkourPlayerFlyState;
   import mmo.game.parkour.game.player.state.ParkourPlayerJumpState;
   import mmo.game.parkour.game.player.state.ParkourPlayerLieDownState;
   import mmo.game.parkour.game.player.state.ParkourPlayerRunState;
   import mmo.game.parkour.game.road.ParkourRoad;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourPlayer extends EventDispatcher
   {
      
      private static const JumpSpeedByJumpTimes:Array = [-27,-27,-27];
      
      public static const InitX:int = 60 * ParkourGameConfig.MeterToPixel;
      
      public static const AccY:int = 4;
      
      public static const Die:String = "Die";
      
      private var avatar:Avatar;
      
      private var stateMap:Object = {};
      
      private var currentStateType:int;
      
      private var roleSkill:IParkourRoleSkill;
      
      private var role:ParkourRoleUserData;
      
      private var _param:ParkourPlayerParam;
      
      private var _ridePetData:ParkourRidePetUserData;
      
      private var _resRoleAblitily:ParkourRoleAbility = new ParkourRoleAbility(0,0,0,0,0);
      
      private var callback:Function = null;
      
      public function ParkourPlayer(param1:ParkourRoleUserData, param2:ParkourRidePetUserData)
      {
         super();
         this.role = param1;
         this._ridePetData = param2;
         this._param = new ParkourPlayerParam();
      }
      
      public function initRoleSkill() : void
      {
         var _loc1_:Class = this.role.skillClass;
         if(_loc1_ != null)
         {
            this.roleSkill = new _loc1_() as IParkourRoleSkill;
            this.roleSkill.init(this.role.skillparams);
         }
      }
      
      public function playRoleSkllPreMovie(param1:Function = null) : void
      {
         this.avatar.playRoleSkillMovie(param1);
      }
      
      public function validateRoleSkill() : Boolean
      {
         if(this.roleSkill != null)
         {
            return this.roleSkill.validate();
         }
         return false;
      }
      
      public function excuteRoleSkill(param1:Object) : void
      {
         if(this.roleSkill != null)
         {
            this.roleSkill.excute(param1);
         }
      }
      
      public function loadAvatar(param1:Function = null) : void
      {
         this.callback = param1;
         CommonEventDispatcher.instance.addEventListener(ParkourEvent.AVATAR_LOAD_COMPLETED,this.onLoadCompleted);
         this.avatar = new Avatar(this.role.id,this.ridePetData.info.id);
      }
      
      private function onLoadCompleted(param1:ParkourEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(ParkourEvent.AVATAR_LOAD_COMPLETED,this.onLoadCompleted);
         this.stateMap[ParkourPlayerStateType.Run] = new ParkourPlayerRunState(this);
         this.stateMap[ParkourPlayerStateType.Jump] = new ParkourPlayerJumpState(this);
         this.stateMap[ParkourPlayerStateType.LieDown] = new ParkourPlayerLieDownState(this);
         this.stateMap[ParkourPlayerStateType.Fly] = new ParkourPlayerFlyState(this);
         this.stateMap[ParkourPlayerStateType.Die] = new ParkourPlayerDieState(this);
         this.x = InitX;
         this.changeState(ParkourPlayerStateType.Run);
         ParkourHelper.applyFunc(this.callback);
         this.callback = null;
      }
      
      public function get roleData() : ParkourRoleUserData
      {
         return this.role;
      }
      
      public function get param() : ParkourPlayerParam
      {
         return this._param;
      }
      
      private function get currentState() : IParkourPlayerState
      {
         return this.stateMap[this.currentStateType];
      }
      
      public function changeState(param1:int) : void
      {
         this.currentStateType = param1;
         this.currentState.onChange();
      }
      
      public function moveYOnRoad(param1:ParkourRoad) : void
      {
         this.currentState.moveYOnRoad(param1);
      }
      
      public function onPressJump() : void
      {
         var _loc1_:int = 0;
         if(this.param.jumpTime < this.param.maxJumpTime)
         {
            _loc1_ = int(JumpSpeedByJumpTimes[this.param.jumpTime]);
            this.jump(_loc1_);
         }
      }
      
      public function jump(param1:int = -20) : void
      {
         this.currentState.jump(param1);
      }
      
      public function lieDown() : void
      {
         this.currentState.lieDown();
      }
      
      public function rise() : void
      {
         this.currentState.rise();
      }
      
      public function die() : void
      {
         if(this.param.invincible)
         {
            return;
         }
         this.changeState(ParkourPlayerStateType.Die);
         dispatchEvent(new Event(Die));
      }
      
      public function fly() : void
      {
         this.currentState.fly();
      }
      
      public function land() : void
      {
         this.currentState.land();
      }
      
      public function action(param1:String) : void
      {
         this.avatar.playAction(param1);
      }
      
      public function roleAction(param1:String) : void
      {
         this.avatar.playRoleAvatarAction(param1);
      }
      
      public function drop() : void
      {
         if(this.param.speedY < 5)
         {
            this.param.speedY = 5;
         }
      }
      
      public function addScore(param1:int) : void
      {
         this.param.addTotalScore(param1);
      }
      
      public function checkMoveXOnRoad(param1:Boolean, param2:int) : void
      {
         if(param1)
         {
            this.view.x += param2;
         }
         else if(this.view.x < InitX)
         {
            this.view.x += 5;
         }
         if(this.getRect().right < 0)
         {
            this.die();
         }
      }
      
      public function isHit(param1:ParkourAbstractMapItem) : Boolean
      {
         var _loc3_:Array = null;
         var _loc2_:Array = this.avatar.getNearPoints();
         for each(_loc3_ in _loc2_)
         {
            if(this.isHitPointArr(_loc3_,param1))
            {
               return true;
            }
         }
         return false;
      }
      
      public function isHitRight(param1:ParkourAbstractMapItem) : Boolean
      {
         var _loc2_:Array = this.avatar.getNearPoints();
         if(_loc2_ == null)
         {
            return false;
         }
         var _loc3_:Array = _loc2_[3];
         return this.isHitPointArr(_loc3_,param1);
      }
      
      public function isHitLeft(param1:ParkourAbstractMapItem) : Boolean
      {
         var _loc2_:Array = this.avatar.getNearPoints();
         if(_loc2_ == null)
         {
            return false;
         }
         var _loc3_:Array = _loc2_[1];
         return this.isHitPointArr(_loc3_,param1);
      }
      
      public function isHitTop(param1:ParkourAbstractMapItem) : Boolean
      {
         var _loc2_:Array = this.avatar.getNearPoints();
         if(_loc2_ == null)
         {
            return false;
         }
         var _loc3_:Array = _loc2_[0];
         return this.isHitPointArr(_loc3_,param1);
      }
      
      public function isHitBottom(param1:ParkourAbstractMapItem, param2:int = 0) : Boolean
      {
         var _loc3_:Array = this.avatar.getNearPoints();
         if(_loc3_ == null)
         {
            return false;
         }
         var _loc4_:Array = _loc3_[2];
         return this.isHitPointArr(_loc4_,param1,0,param2);
      }
      
      private function isHitPointArr(param1:Array, param2:ParkourAbstractMapItem, param3:int = 0, param4:int = 1) : Boolean
      {
         var _loc6_:Point = null;
         if(param1 == null || param1.length == 0)
         {
            return false;
         }
         var _loc5_:int = 0;
         while(_loc5_ < param1.length)
         {
            _loc6_ = param1[_loc5_] as Point;
            _loc6_.x += param3;
            _loc6_.y += param4;
            if(param2.getRect().containsPoint(_loc6_))
            {
               return true;
            }
            _loc5_++;
         }
         return false;
      }
      
      private function get speedOffest() : int
      {
         return ParkourGameScene.instance.mapSpeed;
      }
      
      public function get view() : DisplayObject
      {
         return this.avatar.getAvatarView();
      }
      
      public function get x() : Number
      {
         return this.view.x;
      }
      
      public function get y() : Number
      {
         return this.view.y;
      }
      
      public function set x(param1:Number) : void
      {
         this.view.x = param1;
      }
      
      public function set y(param1:Number) : void
      {
         this.view.y = param1;
      }
      
      private function get minY() : Number
      {
         return 0 + this.getRect().height;
      }
      
      public function getRect() : Rectangle
      {
         return this.avatar.getAreaRectangle();
      }
      
      public function get ridePetData() : ParkourRidePetUserData
      {
         return this._ridePetData;
      }
      
      public function isFlying() : Boolean
      {
         return this.currentStateType == ParkourPlayerStateType.Fly;
      }
      
      public function isDie() : Boolean
      {
         return this.currentStateType == ParkourPlayerStateType.Die;
      }
      
      public function get totalScore() : int
      {
         return this.param.totalScore;
      }
      
      public function get totalMoney() : int
      {
         return this.calMoney(this.param.totalScore);
      }
      
      public function setResRoleAbility(param1:ParkourRoleAbility) : void
      {
         if(param1 == null)
         {
            return;
         }
         this._resRoleAblitily = param1;
      }
      
      private function calMoney(param1:int) : int
      {
         return int(param1 / 40) * (1 + this.role.superCool / 100) * (1 + this.ridePetData.moneyPercent / 100);
      }
      
      public function get flyTimeMillSec() : Number
      {
         return this.role.flyTimeMillSec + this.ridePetData.flyTimeMillSec + this._resRoleAblitily.flyTimeMillSec;
      }
      
      public function get absoreTimeMillSec() : Number
      {
         return this.role.absoreTimeMillSec + this.ridePetData.absoreTimeMillSec + this._resRoleAblitily.absoreTimeMillSec;
      }
      
      public function dispose() : void
      {
         var _loc1_:IParkourPlayerState = null;
         for each(_loc1_ in this.stateMap)
         {
            _loc1_.dispose();
         }
         this.avatar.dispose();
      }
   }
}

