package mmo.game.parkour.game
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.TimerEvent;
   import flash.system.ApplicationDomain;
   import flash.ui.Keyboard;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.parkour.dailytask.ParkourDailyTaskLogger;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleSkillExcuteTime;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   import mmo.game.parkour.game.data.ParkourGameData;
   import mmo.game.parkour.game.effect.ParkourEffectManager;
   import mmo.game.parkour.game.effect.impl.ParkourPlayerFlyByFlyTimeEffect;
   import mmo.game.parkour.game.helper.ParkourRunTimeChecker;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItemManager;
   import mmo.game.parkour.game.panel.ParkourDiePanel;
   import mmo.game.parkour.game.panel.ParkourEndGamePanel;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.game.road.ParkourRoad;
   import mmo.game.parkour.game.sceneitem.barrier.ParkourBarrierManager;
   import mmo.game.parkour.game.sceneitem.coin.ParkourCoinManager;
   import mmo.game.parkour.game.sceneitem.enemy.ParkourEnemyManager;
   import mmo.game.parkour.game.sceneitem.prop.ParkourPropManager;
   import mmo.game.parkour.game.teach.ParkourTeachHelper;
   import mmo.game.parkour.game.ui.ParkourGameUI;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.game.parkour.movie.ParkourMovieContainer;
   import mmo.game.parkour.panel.ParkourMainPanel;
   import mmo.interfaces.IDispose;
   import mmo.loader.LoaderContainer;
   import mmo.loader.scheduler.ResScheduler;
   
   public class ParkourGameScene extends Sprite implements IDispose
   {
      
      private static var _instance:ParkourGameScene;
      
      private var isPause:Boolean = false;
      
      private var field:int = 0;
      
      private var player:ParkourPlayer;
      
      private var road:ParkourRoad;
      
      private var barrierManager:ParkourBarrierManager;
      
      private var enemyManager:ParkourEnemyManager;
      
      private var coinManager:ParkourCoinManager;
      
      private var propManager:ParkourPropManager;
      
      private var ui:ParkourGameUI;
      
      private var effectManager:ParkourEffectManager;
      
      private var gameRunTime:ConfuseInteger = new ConfuseInteger();
      
      private var data:ParkourGameData;
      
      private var teachHelper:ParkourTeachHelper;
      
      private var logMeter:int;
      
      private var logRank:int;
      
      private var runTimer:Timer;
      
      private var backGround:ParkourGameBackGround;
      
      private var movieContainer:ParkourMovieContainer;
      
      private var logFrameRate:int;
      
      private var logJumpTime:int;
      
      internal const maxY:int = 360;
      
      internal const minY:int = 200;
      
      public function ParkourGameScene(param1:int, param2:ParkourRoleUserData, param3:ParkourRidePetUserData, param4:int, param5:int, param6:Boolean = false)
      {
         super();
         if(instance != null)
         {
            throw new Error("以前的ParkourGameScene实例未释放!!!");
         }
         _instance = this;
         this.field = param1;
         this.backGround = new ParkourGameBackGround(param1);
         this.teachHelper = new ParkourTeachHelper(param6);
         this.data = new ParkourGameData();
         this.player = new ParkourPlayer(param2,param3);
         this.road = new ParkourRoad();
         this.barrierManager = new ParkourBarrierManager();
         this.enemyManager = new ParkourEnemyManager();
         this.coinManager = new ParkourCoinManager();
         this.propManager = new ParkourPropManager();
         this.ui = new ParkourGameUI();
         this.effectManager = new ParkourEffectManager();
         this.movieContainer = new ParkourMovieContainer();
         this.runTimer = new Timer(1000);
         this.logFrameRate = LoaderContainer.instance.stage.frameRate;
      }
      
      public static function get instance() : ParkourGameScene
      {
         return _instance;
      }
      
      public function showPanel() : void
      {
         var panel:Sprite = null;
         SundriesClient.logEvent(11408);
         panel = this;
         ProgressFullSprite.show();
         // aola-revival: the 2013 ResScheduler.getResource (into the current domain) for getRes(ResParams…).
         ResScheduler.getResource(ParkourGameResConfig.PreNameOfGameSceneResObj + this.field,function(... rest):void
         {
            var onLoadAvatarOver:*;
            ProgressFullSprite.close();
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(panel,AlignType.NONE);
            onLoadAvatarOver = function():void
            {
               backGround.loadView();
               ProgressFullSprite.close();
               teachHelper.checkLoadFla(initGame);
            };
            ProgressFullSprite.show();
            player.loadAvatar(onLoadAvatarOver);
         });
      }
      
      public function relive(param1:Boolean = false) : void
      {
         if(this.player.isDie())
         {
            ParkourDailyTaskLogger.instance.logRelive();
            if(!param1)
            {
               ++this.data.reliveTimes;
            }
            this.effectManager.excuteEffect(ParkourPlayerFlyByFlyTimeEffect,null);
            this.continueGame();
         }
      }
      
      public function pause() : void
      {
         this.isPause = true;
      }
      
      public function continueGame() : void
      {
         this.isPause = false;
      }
      
      private function initGame() : void
      {
         var _loc2_:Array = null;
         addChild(this.backGround);
         addChild(this.road.getContainer());
         addChild(this.barrierManager.getContainer());
         addChild(this.enemyManager.getContainer());
         addChild(this.coinManager.getContainer());
         addChild(this.propManager.getContainer());
         addChild(this.player.view);
         addChild(this.ui.view);
         addChild(this.movieContainer.getContainer());
         if(this.teachHelper.isNeedTeach())
         {
            this.buildMap(ParkourGameMapConfig.TeachMap);
         }
         var _loc1_:int = 0;
         while(_loc1_ < 4)
         {
            _loc2_ = ParkourGameMapConfig.getMap(this.data.mapWidthMeter);
            this.buildMap(_loc2_);
            _loc1_++;
         }
         this.player.y = this.road.getRoadY(this.player.x);
         this.ui.refresh();
         this.player.initRoleSkill();
         this.movieContainer.playStartMovie(this.restartGame);
         LoaderContainer.instance.stage.focus = this;
      }
      
      private function restartGame() : void
      {
         this.excuteRoleSkill(ParkourRoleSkillExcuteTime.OnAppear,null,this.startGame);
      }
      
      public function excuteRoleSkill(param1:int, param2:Object = null, param3:Function = null) : Boolean
      {
         var onSkillMovieEnd:Function;
         var time:int = param1;
         var params:Object = param2;
         var afterSkillMovie:Function = param3;
         if(time != this.player.roleData.skillExcuteTime)
         {
            ParkourHelper.applyFunc(afterSkillMovie);
            return false;
         }
         if(!this.player.validateRoleSkill())
         {
            ParkourHelper.applyFunc(afterSkillMovie);
            return false;
         }
         onSkillMovieEnd = function():void
         {
            player.excuteRoleSkill(params);
            ParkourHelper.applyFunc(afterSkillMovie);
         };
         this.player.playRoleSkllPreMovie(onSkillMovieEnd);
         return true;
      }
      
      public function get mapSpeed() : int
      {
         return this.data.mapSpeedOfFrame;
      }
      
      private function startGame() : void
      {
         addEventListener(Event.ENTER_FRAME,this.onFrame);
         stage.addEventListener(KeyboardEvent.KEY_UP,this.onPressKeyUp);
         stage.addEventListener(KeyboardEvent.KEY_DOWN,this.onPressKeyDown);
         this.player.addEventListener(ParkourPlayer.Die,this.onPlayerDie);
         this.runTimer.addEventListener(TimerEvent.TIMER,this.onTimer);
         this.runTimer.start();
      }
      
      private function onTimer(param1:TimerEvent) : void
      {
         if(this.isPause)
         {
            return;
         }
         this.gameRunTime.add(1);
      }
      
      public function speedUp() : void
      {
         this.data.offestSpeed = -10;
      }
      
      public function resumeSpeed() : void
      {
         this.data.offestSpeed = 0;
      }
      
      public function getField() : int
      {
         return this.field;
      }
      
      public function getRoad() : ParkourRoad
      {
         return this.road;
      }
      
      public function getBarrierManager() : ParkourBarrierManager
      {
         return this.barrierManager;
      }
      
      public function getCoinManager() : ParkourCoinManager
      {
         return this.coinManager;
      }
      
      public function getEffectManager() : ParkourEffectManager
      {
         return this.effectManager;
      }
      
      public function getEnemyManager() : ParkourEnemyManager
      {
         return this.enemyManager;
      }
      
      public function getPlayer() : ParkourPlayer
      {
         return this.player;
      }
      
      public function get moveMeter() : int
      {
         return this.road.totalMoveMeter;
      }
      
      private function onPlayerDie(param1:Event) : void
      {
         this.isPause = true;
         if(!this.excuteRoleSkill(ParkourRoleSkillExcuteTime.OnDie))
         {
            new ParkourDiePanel(this.data.reliveTimes,this.gameRunTime.getValue(),this.road.totalMoveMeter,this.player.totalScore,this.player.totalMoney,this.logMeter,this.logRank,this.showEndGamePanel).showPanel();
         }
      }
      
      public function showEndGamePanel() : void
      {
         new ParkourEndGamePanel(this.gameRunTime.getValue(),this.road.totalMoveMeter,this.player.totalScore,this.player.totalMoney,this.logMeter,this.logRank,this.unLoadGame).showPanel();
      }
      
      private function onFrame(param1:Event) : void
      {
         if(this.isPause)
         {
            return;
         }
         var _loc2_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc2_.log();
         this.checkCreate();
         this.checkHit();
         this.moveAll();
         this.checkDispose();
         this.runEffect();
         this.checkAbsorb();
         this.ui.refresh();
         this.checkTeach();
         this.checkPlayerPowerFull();
         this.checkAddSpeed();
      }
      
      private function runEffect() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         this.effectManager.runEffectCount();
         _loc1_.traceRunTime("--------效果耗时-------");
      }
      
      private function checkAbsorb() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         this.coinManager.checkAbsorbByPlayer(this.player);
         this.propManager.checkAbsorbByPlayer(this.player);
         _loc1_.traceRunTime("--------吸收耗时-------");
      }
      
      private function checkTeach() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         this.teachHelper.checkTeach(this.road.totalMoveDistance);
         _loc1_.traceRunTime("--------查询教学耗时-------");
      }
      
      private function checkPlayerPowerFull() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         if(this.player.param.power >= ParkourGameConfig.MaxPower)
         {
            this.movieContainer.playPowerFullMovie();
         }
         _loc1_.traceRunTime("--------查询能量耗时-------");
      }
      
      private function checkAddSpeed() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         if(this.road.totalMoveMeter - this.data.logAddSpeedMeter >= 5000)
         {
            this.data.mapSpeedMeter -= 10;
            this.data.logAddSpeedMeter = this.road.totalMoveMeter;
         }
         _loc1_.traceRunTime("--------查询加速耗时-------");
      }
      
      private function checkCreate(param1:int = 0) : void
      {
         var _loc2_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc2_.log();
         var _loc3_:Array = ParkourGameMapConfig.getMap(this.data.mapWidthMeter);
         this.buildMap(_loc3_);
         var _loc4_:int = this.road.totalMoveDistance / ParkourGameConfig.MeterToPixel;
         this.enemyManager.checkCreateMissile(_loc4_);
         _loc2_.traceRunTime("--------创建耗时-------");
      }
      
      private function buildMap(param1:Array) : void
      {
         var _loc5_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         if(this.data.mapWidth > this.road.totalMoveDistance + 2 * ParkourGameConfig.Width)
         {
            return;
         }
         var _loc2_:int = this.data.mapWidth - this.road.totalMoveDistance;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < param1.length)
         {
            _loc5_ = param1[_loc4_] as Array;
            _loc6_ = _loc4_ * ParkourGameMapConfig.Interval_Height;
            _loc7_ = 0;
            while(_loc7_ < _loc5_.length)
            {
               _loc8_ = _loc2_ + _loc7_ * ParkourGameMapConfig.Interval_Width;
               _loc9_ = int(_loc5_[_loc7_]);
               if(_loc9_ == ParkourGameMapConfig.Empty && this.checkCreateItem(param1,_loc4_,_loc7_,_loc9_))
               {
                  this.checkCreateProp(_loc8_,_loc6_);
               }
               else
               {
                  this.createMapPart(_loc9_,_loc8_,_loc6_);
               }
               _loc7_++;
            }
            _loc3_ = Math.max(_loc3_,_loc5_.length * ParkourGameMapConfig.Interval_Width);
            _loc4_++;
         }
         this.data.mapWidth += _loc3_;
         this.onBuildOver();
      }
      
      private function checkCreateItem(param1:Array, param2:int, param3:int, param4:int) : Boolean
      {
         var _loc8_:Array = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc5_:int = ParkourGameMapConfig.getWidthByType(_loc10_);
         var _loc6_:int = ParkourGameMapConfig.getHeightByType(_loc10_);
         var _loc7_:int = 0;
         while(_loc7_ < param1.length)
         {
            _loc8_ = param1[_loc7_] as Array;
            _loc9_ = param3 - 4;
            while(_loc9_ <= param3 + _loc6_)
            {
               if(!(param2 == _loc7_ && param3 == _loc9_))
               {
                  _loc10_ = int(_loc8_[_loc9_]);
                  _loc11_ = ParkourGameMapConfig.getWidthByType(_loc10_);
                  _loc12_ = ParkourGameMapConfig.getHeightByType(_loc10_);
                  if(ParkourHelper.inInRange(param2,_loc7_,_loc12_) && ParkourHelper.inInRange(param3,_loc9_,_loc11_))
                  {
                     return false;
                  }
                  if(_loc10_ != ParkourGameMapConfig.Empty && ParkourHelper.inInRange(_loc7_,param2,_loc6_) && ParkourHelper.inInRange(_loc9_,param3,_loc5_))
                  {
                     return false;
                  }
               }
               _loc9_++;
            }
            _loc7_++;
         }
         return true;
      }
      
      private function checkCreateProp(param1:Number, param2:Number) : void
      {
         var _loc3_:int = 0;
         if(param2 < this.maxY && param2 >= this.minY)
         {
            _loc3_ = (this.road.totalMoveDistance + param1) / ParkourGameConfig.MeterToPixel;
            this.propManager.checkCreateByMapMeter(_loc3_,param1,param2);
         }
      }
      
      private function onBuildOver() : void
      {
         var _loc2_:ParkourAbstractMapItemManager = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.mapItemManagers.length)
         {
            _loc2_ = this.mapItemManagers[_loc1_] as ParkourAbstractMapItemManager;
            _loc2_.buildOver();
            _loc1_++;
         }
      }
      
      private function createMapPart(param1:int, param2:Number, param3:Number) : void
      {
         var _loc5_:ParkourAbstractMapItemManager = null;
         if(param1 == ParkourGameMapConfig.Empty)
         {
            return;
         }
         var _loc4_:int = 0;
         while(_loc4_ < this.mapItemManagers.length)
         {
            _loc5_ = this.mapItemManagers[_loc4_] as ParkourAbstractMapItemManager;
            if(_loc5_.create(param1,param2,param3))
            {
               break;
            }
            _loc4_++;
         }
      }
      
      private function moveAll() : void
      {
         var _loc4_:ParkourAbstractMapItemManager = null;
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         var _loc2_:int = 0;
         while(_loc2_ < this.mapItemManagers.length)
         {
            _loc4_ = this.mapItemManagers[_loc2_] as ParkourAbstractMapItemManager;
            _loc4_.move(this.data.mapSpeedOfFrame);
            _loc2_++;
         }
         this.player.moveYOnRoad(this.road);
         var _loc3_:Boolean = false;
         _loc3_ = this.barrierManager.isHitPlayerRight(this.player) || this.road.isHinderPlayer(this.player);
         _loc3_ &&= !this.player.param.invincible;
         this.player.checkMoveXOnRoad(_loc3_,this.data.mapSpeedOfFrame);
         _loc1_.traceRunTime("--------移动耗时-------");
      }
      
      private function checkHit() : void
      {
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         this.enemyManager.checkHitPlayer(this.player);
         this.coinManager.checkHitPlayer(this.player);
         this.propManager.checkHitPlayer(this.player);
         this.barrierManager.checkHitPlayerTop(this.player);
         this.barrierManager.checkHitPlayerBottom(this.player);
         _loc1_.traceRunTime("--------碰撞耗时-------");
      }
      
      private function checkDispose() : void
      {
         var _loc3_:ParkourAbstractMapItemManager = null;
         var _loc1_:ParkourRunTimeChecker = new ParkourRunTimeChecker();
         _loc1_.log();
         var _loc2_:int = 0;
         while(_loc2_ < this.mapItemManagers.length)
         {
            _loc3_ = this.mapItemManagers[_loc2_] as ParkourAbstractMapItemManager;
            _loc3_.checkDispose();
            _loc2_++;
         }
         this.effectManager.checkDispose();
         _loc1_.traceRunTime("--------销毁耗时-------");
      }
      
      private function get mapItemManagers() : Array
      {
         return [this.road,this.barrierManager,this.enemyManager,this.coinManager,this.propManager];
      }
      
      private function onPressKeyDown(param1:KeyboardEvent) : void
      {
         if(this.isPause && !this.teachHelper.validatePress(param1.keyCode))
         {
            return;
         }
         if(param1.keyCode == Keyboard.UP)
         {
            if(this.logJumpTime == 0 || getTimer() - this.logJumpTime > 130)
            {
               this.logJumpTime = getTimer();
               this.player.onPressJump();
            }
         }
         else if(param1.keyCode == Keyboard.DOWN)
         {
            this.player.lieDown();
         }
      }
      
      private function onPressKeyUp(param1:KeyboardEvent) : void
      {
         if(this.isPause && !this.teachHelper.validatePress(param1.keyCode))
         {
            return;
         }
         if(param1.keyCode == Keyboard.UP)
         {
            this.logJumpTime = 0;
         }
         if(param1.keyCode == Keyboard.DOWN)
         {
            this.player.rise();
         }
         else if(param1.keyCode == Keyboard.SPACE)
         {
            if(!this.player.isFlying() && this.player.param.power >= ParkourGameConfig.MaxPower)
            {
               this.movieContainer.onUsePower();
               this.player.param.power = 0;
               this.effectManager.excuteEffect(this.player.ridePetData.info.effectClass,this.player.ridePetData.info.effectParams);
            }
         }
      }
      
      public function unLoadGame() : void
      {
         this.close();
         new ParkourMainPanel().showPanel();
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function dispose() : void
      {
         var _loc2_:ParkourAbstractMapItemManager = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.mapItemManagers.length)
         {
            _loc2_ = this.mapItemManagers[_loc1_] as ParkourAbstractMapItemManager;
            _loc2_.dispose();
            _loc1_++;
         }
         this.effectManager.dispose();
         this.player.dispose();
         this.ui.dispose();
         removeEventListener(Event.ENTER_FRAME,this.onFrame);
         stage.removeEventListener(KeyboardEvent.KEY_UP,this.onPressKeyUp);
         stage.removeEventListener(KeyboardEvent.KEY_DOWN,this.onPressKeyDown);
         this.player.removeEventListener(ParkourPlayer.Die,this.onPlayerDie);
         this.runTimer.removeEventListener(TimerEvent.TIMER,this.onTimer);
         this.runTimer.stop();
         this.runTimer = null;
         this.teachHelper.dispose();
         this.movieContainer.dispose();
         LoaderContainer.instance.stage.frameRate = this.logFrameRate;
         _instance = null;
      }
   }
}

