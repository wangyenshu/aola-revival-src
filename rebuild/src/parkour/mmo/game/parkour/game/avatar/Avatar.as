package mmo.game.parkour.game.avatar
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.game.parkour.event.ParkourEvent;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.loader.LoaderContainer;
   
   public class Avatar
   {
      
      private static const AVATAR_ROLE_CLS:String = "mmo.game.parkour.game.avatar.Role";
      
      private static const AVATAR_RIDE_CLS:String = "mmo.game.parkour.game.avatar.Ride";
      
      private static const AVATAR_ROLE_SKILL_CLS:String = "mmo.game.parkour.game.avatar.AvatarSkillMovie";
      
      private static const AVATAR_ROLE_CONTAINER_NAME:String = "avatarct";
      
      private static const AVATAR_AREA_NAMES:String = "areamc";
      
      private static const LOCATION_POINT_NAME_PREFIX:String = "location_";
      
      private static const DIRECTIONS:Array = ["U","L","D","R"];
      
      private static const POINT_NUMS:Array = [2,2,4,2];
      
      private var _roleView:MovieClip;
      
      private var _rideView:MovieClip;
      
      private var _avatarContainer:Sprite;
      
      private var _avatarResInfo:AvatarResInfo;
      
      private var _avatarLoader:AvatarLoader;
      
      private var _currentAction:String;
      
      private var _currentRoleAction:String;
      
      private var _ownActions:Array = [];
      
      private var _cacheNearPoints:Object = {};
      
      private var _debugHelper:AvatarDebugHelper = new AvatarDebugHelper();
      
      private var tempContainer:DisplayObjectContainer;
      
      public function Avatar(param1:int, param2:int)
      {
         super();
         this._avatarResInfo = new AvatarResInfo(param1,param2);
         if(this._ownActions == null || this._ownActions.length == 0)
         {
            this._ownActions = AvatarActionCodeHelper.createDefaultCodes();
         }
         this._avatarContainer = new Sprite();
         this._avatarLoader = new AvatarLoader();
         this._avatarLoader.loadAvatarRes(this._avatarResInfo,this.freshView);
      }
      
      public function setAvatarResInfo(param1:AvatarResInfo) : void
      {
         this._avatarResInfo = param1;
         this._avatarLoader.loadAvatarRes(this._avatarResInfo,this.freshView);
      }
      
      private function freshView(param1:ApplicationDomain) : void
      {
         ParkourHelper.clearContainer(this._avatarContainer);
         this.freshAvatarView(param1);
         this.freshRideView(param1);
         this._debugHelper.openDebug(this.getAreaRectangle);
         CommonEventDispatcher.instance.dispatchEvent(new ParkourEvent(ParkourEvent.AVATAR_LOAD_COMPLETED));
         this.playAction(AvatarActionCodeHelper.RUN);
         this.playRoleAvatarAction(AvatarActionCodeHelper.ROLE_NORMAL);
      }
      
      private function freshAvatarView(param1:ApplicationDomain) : void
      {
         var _loc2_:Class = param1.getDefinition(AVATAR_ROLE_CLS + this._avatarResInfo.roldId) as Class;
         this._roleView = new _loc2_() as MovieClip;
         this._roleView.gotoAndStop(1);
      }
      
      private function freshRideView(param1:ApplicationDomain) : void
      {
         var _loc2_:Class = param1.getDefinition(AVATAR_RIDE_CLS + this._avatarResInfo.rideId) as Class;
         this._rideView = new _loc2_() as MovieClip;
         this._avatarContainer.addChild(this._rideView);
      }
      
      private function mergeAvatarAndRideView() : void
      {
         this._rideView.gotoAndStop(this._currentAction);
         var _loc1_:MovieClip = this._rideView.getChildByName("mc") as MovieClip;
         var _loc2_:DisplayObjectContainer = this.getRoleContainer(_loc1_) as DisplayObjectContainer;
         ParkourHelper.clearContainer(_loc2_);
         _loc2_.addChild(this._roleView);
         this.cacheRideViewNearPoints();
         _loc1_.gotoAndPlay(1);
      }
      
      public function getNearPoints() : Array
      {
         var _loc1_:MovieClip = this._rideView.getChildByName("mc") as MovieClip;
         var _loc2_:Array = this._cacheNearPoints[this._currentAction][_loc1_.currentFrame - 1];
         return this.getNearPointsByRideMC(_loc1_);
      }
      
      private function getRoleContainer(param1:DisplayObjectContainer) : DisplayObjectContainer
      {
         var _loc2_:DisplayObjectContainer = param1.getChildByName(AVATAR_ROLE_CONTAINER_NAME) as DisplayObjectContainer;
         if(_loc2_ != null && _loc2_ is DisplayObjectContainer)
         {
            this.tempContainer = _loc2_;
            return this.getRoleContainer(_loc2_);
         }
         return this.tempContainer;
      }
      
      public function getAreaRectangle() : Rectangle
      {
         var _loc1_:DisplayObject = Sprite(this._rideView.getChildByName("mc")).getChildByName(AVATAR_AREA_NAMES) as DisplayObject;
         if(_loc1_ == null)
         {
            _loc1_ = this._rideView;
         }
         return _loc1_.getRect(LoaderContainer.instance.stage);
      }
      
      public function getCurrentAction() : String
      {
         return this._currentAction;
      }
      
      public function getAvatarView() : Sprite
      {
         return this._avatarContainer;
      }
      
      public function isAllow(param1:String) : Boolean
      {
         if(this._ownActions.indexOf(param1) != -1)
         {
            return true;
         }
         return false;
      }
      
      private function isSameAction(param1:String) : Boolean
      {
         return this._currentAction == param1;
      }
      
      public function playRoleAvatarAction(param1:String) : void
      {
         if(this.isSameAction(param1))
         {
            return;
         }
         this._currentRoleAction = param1;
         this._roleView.gotoAndStop(this._currentRoleAction);
      }
      
      public function playRoleSkillMovie(param1:Function) : void
      {
         var skillMovieCls:Class;
         var skillMovie:MovieClip = null;
         var callBack:Function = param1;
         var skillClsName:String = AVATAR_ROLE_SKILL_CLS + this._avatarResInfo.roldId;
         if(!this._avatarLoader.currentDomain.hasDefinition(skillClsName))
         {
            callBack.apply();
            return;
         }
         skillMovieCls = this._avatarLoader.currentDomain.getDefinition(skillClsName) as Class;
         skillMovie = new skillMovieCls() as MovieClip;
         skillMovie.addFrameScript(skillMovie.totalFrames - 1,function():void
         {
            ModalDialogManager.getInstance().removeModalDialog(skillMovie);
            callBack.apply();
         });
         skillMovie.gotoAndPlay(1);
         ModalDialogManager.getInstance().addModalDialog(skillMovie,AlignType.NONE);
      }
      
      public function playAction(param1:String) : void
      {
         if(!this.isAllow(param1))
         {
            return;
         }
         if(this.isSameAction(param1))
         {
            return;
         }
         this._currentAction = param1;
         this.mergeAvatarAndRideView();
      }
      
      private function cacheRideViewNearPoints() : void
      {
         var _loc1_:Array = [];
         var _loc2_:MovieClip = this._rideView.getChildByName("mc") as MovieClip;
         var _loc3_:int = 1;
         while(_loc3_ <= _loc2_.totalFrames)
         {
            _loc2_.gotoAndStop(_loc3_);
            _loc1_.push(this.getNearPointsByRideMC(_loc2_));
            _loc3_++;
         }
         this._cacheNearPoints[this._currentAction] = _loc1_;
         _loc2_.gotoAndPlay(1);
      }
      
      private function getNearPointsByRideMC(param1:MovieClip) : Array
      {
         var _loc4_:Array = null;
         var _loc5_:int = 0;
         var _loc6_:DisplayObject = null;
         var _loc7_:Point = null;
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < DIRECTIONS.length)
         {
            _loc4_ = [];
            _loc5_ = 0;
            while(_loc5_ < POINT_NUMS[_loc3_])
            {
               _loc6_ = param1.getChildByName(LOCATION_POINT_NAME_PREFIX + DIRECTIONS[_loc3_] + _loc5_) as DisplayObject;
               if(_loc6_ != null)
               {
                  _loc7_ = _loc6_.parent.localToGlobal(new Point(_loc6_.x,_loc6_.y));
                  _loc4_.push(_loc7_);
               }
               _loc5_++;
            }
            _loc2_.push(_loc4_);
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this._roleView);
         DisplayUtil.stopAndRemove(this._rideView);
         this._ownActions = null;
         this._roleView = null;
         this._rideView = null;
         this._cacheNearPoints = null;
         if(this._debugHelper != null)
         {
            this._debugHelper.closeDebug();
            this._debugHelper = null;
         }
         if(this._avatarLoader != null)
         {
            this._avatarLoader.dispose();
            this._avatarContainer = null;
         }
      }
   }
}

