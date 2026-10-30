package mmo.sceneinit
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.ISceneInitExt;
   import mmo.interfaces.InitServiceEvent;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;

   /**
    * REBUILT init/sceneinit (ServiceConfig "SceneInit", IInitService and
    * ISceneInitExt). The January 2013 module is lost; the later copy (2022)
    * plays each scene's music when the scene is entered (SceneMusic) and
    * shows the scene's name, and that later build calls services the 2013
    * client does not have. This keeps the music, after the later SceneMusic,
    * on the 2013 SoundManager (common library) and the 2013 config.xml
    * (ConfigReader.getSceneMusic: a room's mu, one file or several to pick
    * from). The scene name banner of the later copy is left out: nothing
    * shows that 2013 had it.
    */
   public class SceneInit extends EventDispatcher implements IInitService, ISceneInitExt
   {
      private var music:SceneMusic;
      private var _canShowScoreOut:Boolean = true;

      public function SceneInit()
      {
         super();
      }

      public function init():void
      {
         music = new SceneMusic();
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onInitScene);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.GAME_INITED, onInitGame);
         if (SceneManager.getInstance().loadedSceneInfo != null) onInitScene(null);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function get canShowScoreOut():Boolean
      {
         return _canShowScoreOut;
      }

      public function set canShowScoreOut(v:Boolean):void
      {
         _canShowScoreOut = v;
      }

      private function onInitScene(e:SceneManagerEvent):void
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info != null) music.playSceneMusic(String(info.sceneName));
      }

      private function onInitGame(e:SceneManagerEvent):void
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info != null) music.playGameMusic(String(info.sceneName));
      }
   }
}
