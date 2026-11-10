package mmo.game.flyingfruit
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.ui.Keyboard;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.flyingfruit.panel.StartPanel;
   import mmo.game.flyingfruit.sound.SongController;
   import mmo.loader.LoaderContainer;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FlyingFruitManager extends MovieClip
   {
      
      private static var _instance:FlyingFruitManager = null;
      
      private static const CMD_YABIZHIHUN:String = "CF160527_panel";
      
      private var startMovie:MovieClip = null;
      
      public var curScore:Number = 0;
      
      public var isGameOver:Boolean = false;
      
      private const EXT:String = "HolidayExtension";
      
      private const cmdGetGift:String = "20120713_11";
      
      private var isChengnanBack:Boolean = false;
      
      private var isSceneInited:Boolean = false;
      
      private var _myYaBiZhiHun:int = 0;
      
      public function FlyingFruitManager()
      {
         super();
         _instance = this;
         SundriesClient.logButton(7718);
         // REVIVAL: the start panel at once (it waited for the count of 亚比之魂 of a 2016 activity,
         // HolidayExtension CF160527_panel, which this world has not).
         this.addPrePanel();
      }
      
      public static function get instance() : FlyingFruitManager
      {
         if(_instance == null)
         {
            _instance = new FlyingFruitManager();
         }
         return _instance;
      }
      
      private function addPrePanel() : void
      {
         SocketClient.instance.addEventListener(this.cmdGetGift,this.onListenGetGift);
         SongController.getInstance().stopSceneBgSound();
         SongController.getInstance().playBGSound();
         var _loc1_:StartPanel = new StartPanel();
         _loc1_.setYabizhiHun(this._myYaBiZhiHun);
         this.addChild(_loc1_ as MovieClip);
      }
      
      public function startGame() : void
      {
         SocketClient.instance.sendXtMessage("SundriesExtension","70_7",{"GameName":"gameFlyingFruit"});
         this.curScore = 0;
         this.isGameOver = false;
         this.addChild(FFInstanceManager.instance().mainPanel);
         this.playStartMovie();
      }
      
      private function playStartMovie() : void
      {
         var _loc1_:Class = null;
         if(this.startMovie == null)
         {
            _loc1_ = getDefinitionByName("mmo.game.flyingfruit.panel.StartMovie") as Class;
            this.startMovie = new _loc1_() as MovieClip;
            this.startMovie.x = 480;
            this.startMovie.y = 280;
         }
         this.addChild(this.startMovie);
         this.startMovie.addFrameScript(this.startMovie.totalFrames - 1,this.onStartMovieEnd);
         this.startMovie.gotoAndPlay(1);
      }
      
      private function onStartMovieEnd() : void
      {
         this.startMovie.addFrameScript(this.startMovie.totalFrames - 1,function():void
         {
         });
         this.startMovie.gotoAndStop(1);
         DisplayUtil.stopAndRemove(this.startMovie);
         SongController.getInstance().playBeginSound();
         LoaderContainer.instance.stage.addEventListener(KeyboardEvent.KEY_DOWN,this.onListenKeyDown);
         CommonEventDispatcher.instance.addEventListener("FLYINGDISK_QUIT_GAME",this.onListenQuitGame);
         CommonEventDispatcher.instance.addEventListener("FLYINGDISK_RESTART_GAME",this.onListenRestartGame);
         FFInstanceManager.instance().mainPanel.addEventListeners();
         FFInstanceManager.instance().mainPanel.setDingdingPlay();
         FFInstanceManager.instance().adderManager.startAdd();
         FFInstanceManager.instance().hitManager.startCheck();
         LoaderContainer.instance.stage.focus = this;
      }
      
      private function onListenKeyDown(param1:KeyboardEvent) : void
      {
         if(param1.keyCode != Keyboard.SPACE || FFInstanceManager.instance().enterFrameManager.isPause)
         {
            return;
         }
         SongController.getInstance().playBombSound();
         FFInstanceManager.instance().mainPanel.addBombMovie();
      }
      
      private function onListenQuitGame(param1:Event) : void
      {
         this.disposeGame();
      }
      
      private function onListenRestartGame(param1:Event) : void
      {
         FFInstanceManager.instance().dispose();
         this.startGame();
      }
      
      public function refreshScore(param1:Number) : void
      {
         if(this.isGameOver)
         {
            return;
         }
         this.curScore += param1;
         if(this.curScore < 0)
         {
            this.curScore = 0;
         }
         FFInstanceManager.instance().mainPanel.refreshScore();
      }
      
      public function showGameOverPanel() : void
      {
         this.isGameOver = true;
         FFInstanceManager.instance().enterFrameManager.pause();
         FFInstanceManager.instance().mainPanel.setDingdingStop();
         var _loc1_:Class = getDefinitionByName("mmo.game.flyingfruit.panel.GameOverPanel") as Class;
         var _loc2_:MovieClip = new _loc1_(this.curScore,1) as MovieClip;
         this.addChild(_loc2_);
      }
      
      public function disposeGame() : void
      {
         this.dispose();
         SceneManager.getInstance().unloadGame();
      }
      
      public function dispose() : void
      {
         this.startMovie = null;
         LoaderContainer.instance.stage.removeEventListener(KeyboardEvent.KEY_DOWN,this.onListenKeyDown);
         CommonEventDispatcher.instance.removeEventListener("FLYINGDISK_QUIT_GAME",this.onListenQuitGame);
         CommonEventDispatcher.instance.removeEventListener("FLYINGDISK_RESTART_GAME",this.onListenRestartGame);
         FFInstanceManager.instance().dispose();
         SongController.dispose();
         _instance = null;
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
      }
      
      private function onListenGetGift(param1:SocketClientEvent) : void
      {
         this.isChengnanBack = true;
         this.checkSendCmd();
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         this.isSceneInited = true;
         this.checkSendCmd();
      }
      
      private function checkSendCmd() : void
      {
         if(this.isChengnanBack && this.isSceneInited)
         {
            CommonEventDispatcher.instance.dispatchEvent(new Event("BINRENXIA_TODAY_DOWN "));
         }
      }
      
      private function sendGetYabiZhihunCmd() : void
      {
         SocketClient.instance.addEventListener(CMD_YABIZHIHUN,this.afterGetYabiZhiHun);
         SocketClient.instance.sendXtMessage(this.EXT,CMD_YABIZHIHUN,{});
      }
      
      private function afterGetYabiZhiHun(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(CMD_YABIZHIHUN,this.afterGetYabiZhiHun);
         this._myYaBiZhiHun = param1.params.coin;
         this.addPrePanel();
      }
   }
}

