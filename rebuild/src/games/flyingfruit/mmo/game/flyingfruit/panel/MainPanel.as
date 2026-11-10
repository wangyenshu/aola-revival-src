package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.flyingfruit.FFInstanceManager;
   import mmo.game.flyingfruit.FlyingFruitManager;
   import mmo.game.flyingfruit.sound.SongController;
   
   public class MainPanel extends MovieClip
   {
      
      public var angerbar:MovieClip;
      
      public var background:MovieClip;
      
      public var t1:MovieClip;
      
      public var score:TextField;
      
      public var t2:MovieClip;
      
      public var t3:MovieClip;
      
      public var t4:MovieClip;
      
      public var movielayer:MovieClip;
      
      public var doubleMovie:MovieClip;
      
      public var btnClose:SimpleButton;
      
      public var downdoublemovie:MovieClip;
      
      public var disklayer:MovieClip;
      
      public var throwBomb:MovieClip;
      
      public var anger:TextField;
      
      public var bombNum:TextField;
      
      public var bombbar:MovieClip;
      
      private const BOMB_NUM:int = 50;
      
      private const ANGER_NUM:int = 10;
      
      public var mcGun:MovieClip;
      
      private var mcDingding:MovieClip;
      
      public var backGround:MovieClip;
      
      private var diskLayer:MovieClip;
      
      private var movieLayer:MovieClip;
      
      private var isShooting:Boolean = false;
      
      public var gunXPos:Number;
      
      public var gunYPose:Number;
      
      public var dingdingXPos:Number;
      
      public var isWaitSpace:Boolean = false;
      
      private var bombMovie:MovieClip = null;
      
      private var endMovie:MovieClip;
      
      private var curTime:int;
      
      private var btnBomb:MovieClip;
      
      private var txtBombNum:TextField;
      
      private var curBombNum:int = 0;
      
      private var txtScore:TextField;
      
      private var txtAnger:TextField;
      
      private var mcThrowBomb:MovieClip;
      
      private var mcDouble:MovieClip;
      
      private var downDouble:MovieClip;
      
      private var curAnger:int = 0;
      
      private var angerPanel:MovieClip;
      
      private var bombPanel:MovieClip;
      
      private var isShowBombPanel:Boolean = false;
      
      private var isClickShooting:Boolean = false;
      
      private var bombBar:MovieClip;
      
      private var angerBar:MovieClip;
      
      private var timeIcon1:MovieClip;
      
      private var timeIcon2:MovieClip;
      
      public function MainPanel()
      {
         super();
         SundriesClient.logEvent(16715);
         this.init();
      }
      
      public function get getDiskLayer() : MovieClip
      {
         return this.diskLayer;
      }
      
      private function init() : void
      {
         this.backGround = this.getChildByName("background") as MovieClip;
         this.diskLayer = this.getChildByName("disklayer") as MovieClip;
         this.movieLayer = this.getChildByName("movielayer") as MovieClip;
         this.mcGun = this.backGround.getChildByName("gun") as MovieClip;
         this.mcGun.gotoAndStop(1);
         this.gunXPos = this.mcGun.x;
         this.gunYPose = this.mcGun.y;
         this.mcDingding = this.backGround.getChildByName("dingding") as MovieClip;
         this.dingdingXPos = this.mcDingding.x;
         this.mcDingding.gotoAndStop(1);
         this.txtBombNum = this.getChildByName("bombNum") as TextField;
         this.mcThrowBomb = this.getChildByName("throwBomb") as MovieClip;
         this.mcThrowBomb.visible = false;
         this.btnBomb = this.mcThrowBomb.getChildByName("bombButton") as MovieClip;
         this.btnBomb.gotoAndStop(1);
         this.txtScore = this.getChildByName("score") as TextField;
         this.txtAnger = this.getChildByName("anger") as TextField;
         this.mcDouble = this.getChildByName("doubleMovie") as MovieClip;
         this.mcDouble.gotoAndStop(this.mcDouble.totalFrames);
         this.mcDouble.visible = false;
         this.mcDouble.mouseChildren = false;
         this.mcDouble.mouseEnabled = false;
         this.downDouble = this.getChildByName("downdoublemovie") as MovieClip;
         this.downDouble.gotoAndStop(1);
         this.downDouble.visible = false;
         this.downDouble.mouseChildren = false;
         this.downDouble.mouseEnabled = false;
         var _loc1_:Class = getDefinitionByName("mmo.game.flyingfruit.panel.EndMovie") as Class;
         this.endMovie = new _loc1_() as MovieClip;
         this.endMovie.gotoAndStop(1);
         this.endMovie.x = 480;
         this.endMovie.y = 280;
         this.movieLayer.addChild(this.endMovie);
         this.endMovie.visible = false;
         this.endMovie.mouseChildren = false;
         this.endMovie.mouseEnabled = false;
         _loc1_ = getDefinitionByName("mmo.game.flyingfruit.panel.AngerPanel") as Class;
         this.angerPanel = new _loc1_() as MovieClip;
         this.angerPanel.gotoAndStop(1);
         this.angerPanel.x = 480;
         this.angerPanel.y = 250;
         this.angerPanel.visible = false;
         this.movieLayer.addChild(this.angerPanel);
         this.angerPanel.mouseChildren = false;
         this.angerPanel.mouseEnabledr = false;
         _loc1_ = getDefinitionByName("mmo.game.flyingfruit.panel.BombPanel") as Class;
         this.bombPanel = new _loc1_() as MovieClip;
         this.bombPanel.gotoAndStop(1);
         this.bombPanel.x = 480;
         this.bombPanel.y = 180;
         this.bombPanel.visible = false;
         this.movieLayer.addChild(this.bombPanel);
         this.bombPanel.mouseChildren = false;
         this.bombPanel.mouseEnabled = false;
         this.bombBar = this.getChildByName("bombbar") as MovieClip;
         this.bombBar.gotoAndStop(1);
         this.angerBar = this.getChildByName("angerbar") as MovieClip;
         this.angerBar.gotoAndStop(1);
         this.timeIcon1 = this.getChildByName("t1") as MovieClip;
         this.timeIcon1.gotoAndStop(1);
         this.timeIcon2 = this.getChildByName("t2") as MovieClip;
         this.timeIcon2.gotoAndStop(7);
         SimpleButton(this.getChildByName("btnClose")).addEventListener(MouseEvent.CLICK,this.onClickBtnClose);
      }
      
      public function setDingdingPlay() : void
      {
         this.mcDingding.play();
      }
      
      public function setDingdingStop() : void
      {
         DisplayUtil.stop(this.mcDingding);
      }
      
      private function onClickBtnClose(param1:MouseEvent) : void
      {
         FlyingFruitManager.instance.showGameOverPanel();
      }
      
      public function addEventListeners() : void
      {
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onCheckMouseMove);
         this.addEventListener(MouseEvent.CLICK,this.onMouseClick);
      }
      
      private function onCheckMouseMove() : void
      {
         if(FFInstanceManager.instance().enterFrameManager.isPause)
         {
            return;
         }
         this.changeGunRotation();
      }
      
      private function changeGunRotation() : void
      {
         var _loc1_:Number = mouseX - this.mcGun.x;
         var _loc2_:Number = mouseY - this.mcGun.y;
         var _loc3_:Number = Math.atan(_loc1_ / _loc2_);
         var _loc4_:Number = Math.atan(_loc1_ / _loc2_) * 180 / Math.PI;
         var _loc5_:Number = _loc3_ * 10;
         if(_loc2_ < 0)
         {
            this.mcGun.rotation = -_loc4_;
            this.backGround.x = -_loc5_;
         }
         else
         {
            this.mcGun.rotation = 180 - _loc4_;
            this.backGround.x = _loc5_;
         }
      }
      
      private function onMouseClick(param1:MouseEvent) : void
      {
         if(FFInstanceManager.instance().enterFrameManager.isPause)
         {
            return;
         }
         if(this.isShooting)
         {
            this.isClickShooting = true;
            return;
         }
         this.doShoot();
      }
      
      private function doShoot() : void
      {
         SongController.getInstance().playShootSound();
         this.isShooting = true;
         this.mcGun.addFrameScript(this.mcGun.totalFrames - 1,this.onShootEnd);
         this.mcGun.gotoAndPlay(1);
      }
      
      private function onShootEnd() : void
      {
         this.mcGun.addFrameScript(this.mcGun.totalFrames - 1,function():void
         {
         });
         this.mcGun.gotoAndStop(this.mcGun.totalFrames);
         this.isShooting = false;
         if(this.isClickShooting)
         {
            this.isClickShooting = false;
            this.doShoot();
         }
      }
      
      public function refreshTime(param1:int) : void
      {
         this.curTime = param1;
         var _loc2_:int = 60 - this.curTime;
         this.timeIcon1.gotoAndStop(_loc2_ % 10 + 1);
         this.timeIcon2.gotoAndStop(Math.floor(_loc2_ / 10) + 1);
      }
      
      public function refreshBombNum() : void
      {
         ++this.curBombNum;
         if(this.curBombNum >= this.BOMB_NUM)
         {
            this.mcThrowBomb.visible = true;
            this.btnBomb.gotoAndPlay(1);
            this.txtBombNum.text = this.BOMB_NUM.toString() + "/50";
            this.bombBar.gotoAndStop(this.BOMB_NUM + 1);
            this.isWaitSpace = true;
         }
         else
         {
            this.txtBombNum.text = this.curBombNum.toString() + "/50";
            this.bombBar.gotoAndStop(this.curBombNum + 1);
         }
      }
      
      public function addBombMovie() : void
      {
         var _loc1_:Class = null;
         if(!this.isWaitSpace)
         {
            return;
         }
         this.isWaitSpace = false;
         this.curBombNum = 0;
         this.txtBombNum.text = this.curBombNum.toString() + "/50";
         this.bombBar.gotoAndStop(this.curBombNum + 1);
         this.btnBomb.gotoAndStop(1);
         this.mcThrowBomb.visible = false;
         FFInstanceManager.instance().enterFrameManager.pause();
         if(this.bombMovie == null)
         {
            _loc1_ = getDefinitionByName("mmo.game.flyingfruit.panel.BombMovie") as Class;
            this.bombMovie = new _loc1_() as MovieClip;
            this.bombMovie.mouseChildren = false;
            this.bombMovie.mouseEnabled = false;
            this.bombMovie.x = 480;
            this.bombMovie.y = 200;
            this.addChild(this.bombMovie);
         }
         this.bombMovie.visible = true;
         this.bombMovie.addFrameScript(this.bombMovie.totalFrames - 1,this.onBombMovieEnd);
         this.bombMovie.gotoAndPlay(1);
      }
      
      private function onBombMovieEnd() : void
      {
         FFInstanceManager.instance().diskManager.allDiskesBombWithScore();
         this.bombMovie.visible = false;
         this.bombMovie.addFrameScript(this.bombMovie.totalFrames - 1,function():void
         {
         });
         this.bombMovie.gotoAndStop(1);
         FFInstanceManager.instance().enterFrameManager.play();
      }
      
      public function refreshScore() : void
      {
         this.txtScore.text = FlyingFruitManager.instance.curScore.toString();
      }
      
      public function refreshAnger(param1:int) : void
      {
         if(FFInstanceManager.instance().adderManager.isDoubleScore)
         {
            return;
         }
         this.showAngerPanel(param1);
         this.curAnger += param1;
         if(this.curAnger >= this.ANGER_NUM)
         {
            FFInstanceManager.instance().adderManager.setDoubleScoreTrue();
            this.curAnger = 0;
            this.mcDouble.visible = true;
            this.downDouble.visible = true;
            FFInstanceManager.instance().enterFrameManager.registerFun(this.playDoubleScoreMovie);
         }
         this.txtAnger.text = this.curAnger.toString() + "/10";
         this.angerBar.gotoAndStop(this.curAnger + 1);
      }
      
      private function playDoubleScoreMovie() : void
      {
         this.mcDouble.gotoAndStop(this.mcDouble.currentFrame - 1);
         var _loc1_:TextField = this.mcDouble.getChildByName("time") as TextField;
         _loc1_.text = Math.floor(this.mcDouble.currentFrame / 25 + 1).toString() + "/5秒";
         if(this.mcDouble.currentFrame == 1)
         {
            FFInstanceManager.instance().adderManager.setDoubleScoreFalse();
            this.resetAnger();
         }
      }
      
      public function resetAnger() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.playDoubleScoreMovie);
         FFInstanceManager.instance().adderManager.setDoubleScoreFalse();
         this.mcDouble.visible = false;
         this.mcDouble.gotoAndStop(this.mcDouble.totalFrames);
         this.downDouble.visible = false;
         this.curAnger = 0;
         this.angerBar.gotoAndStop(1);
         this.txtAnger.text = this.curAnger.toString() + "/10";
      }
      
      public function showBombPanel() : void
      {
         this.isShowBombPanel = true;
         this.onAngerEnd();
         this.bombPanel.visible = true;
         this.bombPanel.addFrameScript(this.bombPanel.totalFrames - 1,this.onBombPanelEnd);
         this.bombPanel.gotoAndPlay(1);
      }
      
      private function onBombPanelEnd() : void
      {
         this.isShowBombPanel = false;
         this.bombPanel.addFrameScript(this.bombPanel.totalFrames - 1,function():void
         {
         });
         this.bombPanel.gotoAndStop(1);
         this.bombPanel.visible = false;
      }
      
      public function showAngerPanel(param1:int) : void
      {
         if(this.isShowBombPanel)
         {
            return;
         }
         var _loc2_:TextField = this.angerPanel.getChildByName("angerNum") as TextField;
         _loc2_.text = param1.toString();
         this.angerPanel.addFrameScript(2,this.onAngerMid);
         this.angerPanel.addFrameScript(this.angerPanel.totalFrames - 1,this.onAngerEnd);
         this.angerPanel.gotoAndPlay(1);
      }
      
      private function onAngerMid() : void
      {
         this.angerPanel.addFrameScript(2,function():void
         {
         });
         this.angerPanel.visible = true;
      }
      
      private function onAngerEnd() : void
      {
         this.angerPanel.addFrameScript(this.angerPanel.totalFrames - 1,function():void
         {
         });
         this.angerPanel.gotoAndStop(1);
         this.angerPanel.visible = false;
      }
      
      public function playEndMovie() : void
      {
         SongController.getInstance().playCountDownSound();
         this.endMovie.visible = true;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayEndMovie);
      }
      
      private function onPlayEndMovie() : void
      {
         if(FFInstanceManager.instance().adderManager.isDoubleScore)
         {
            return;
         }
         SongController.getInstance().setCountDownSoundStop();
         this.endMovie.gotoAndStop(this.endMovie.currentFrame + 1);
      }
      
      public function refresEndMovie(param1:int) : void
      {
         if(this.curTime < 50)
         {
            this.endMovie.gotoAndStop(1);
            this.endMovie.visible = false;
            SongController.getInstance().setCountDownSoundStop();
            FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayEndMovie);
            return;
         }
         var _loc2_:int = this.endMovie.currentFrame - param1 * 25;
         if(_loc2_ < 1)
         {
            _loc2_ = 1;
         }
         this.endMovie.gotoAndStop(_loc2_);
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onCheckMouseMove);
         this.removeEventListener(MouseEvent.CLICK,this.onMouseClick);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.playDoubleScoreMovie);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayEndMovie);
         DisplayUtil.stopAndRemove(this);
      }
   }
}

