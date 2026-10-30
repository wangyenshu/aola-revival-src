package mmo.sceneinit
{
   import flash.events.Event;
   import mmo.common.sound.SoundManager;
   import mmo.common.sound.SoundManagerEvent;
   import mmo.config.ConfigReader;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * REBUILT after the later mmo.sceneinit.SceneMusic: the music of the scene
    * (config.xml mu, comma separated: one picked at random each time a piece
    * ends), kept playing across scenes that share it, stopped where a room
    * has none, given back after a battle (whose start stops it) and when the
    * player switches the music on again (SoundManager.switchMusic, the sound
    * switch of the control bar).
    */
   public class SceneMusic
   {
      private var sceneName:String;

      public function SceneMusic()
      {
         SoundManager.instance.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
         SoundManager.instance.addEventListener(SoundManagerEvent.ON_SWITCH_ON, onSwitchOn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_START, onFightStart);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
      }

      public function playSceneMusic(name:String):void
      {
         sceneName = name;
         var files:String = musicOf(name);
         if (files == null || files.length == 0)
         {
            SoundManager.instance.stopBackgroundMusic();
            return;
         }
         if (playingOneOf(files)) return;
         playRandom(files);
      }

      /** A mini game's room plays its music too, and leaves the scene's alone if it has none. */
      public function playGameMusic(name:String):void
      {
         var files:String = musicOf(name);
         if (files == null || files.length == 0) return;
         sceneName = name;
         if (playingOneOf(files)) return;
         playRandom(files);
      }

      private static function musicOf(name:String):String
      {
         try { return ConfigReader.instance.getSceneMusic(name); }
         catch (e:Error) {}
         return null;
      }

      private static function playingOneOf(files:String):Boolean
      {
         var now:String = SoundManager.instance.currentMusic;
         return now != null && files.split(",").indexOf(now) >= 0;
      }

      private function playRandom(files:String):void
      {
         var list:Array = files.split(",");
         var f:String = String(list[Math.floor(Math.random() * list.length)]);
         RLog.log("music: " + f + " (" + sceneName + ")");
         // One piece at a time, not looped: when it ends the next is picked.
         SoundManager.instance.playBackgroundMusic(f, 1, list.length == 1);
      }

      private function onSoundComplete(e:Event):void
      {
         if (sceneName != null && !SoundManager.instance.isClose) playRandom(musicOf(sceneName) || "");
      }

      private function onSwitchOn(e:SoundManagerEvent):void
      {
         if (sceneName != null) playSceneMusic(sceneName);
      }

      private function onFightStart(e:Event):void
      {
         SoundManager.instance.stopBackgroundMusic();
      }

      private function onFightEnd(e:Event):void
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info != null) playSceneMusic(String(info.sceneName));
      }
   }
}
