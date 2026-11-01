package mmo.sceneinit
{
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.media.Sound;
   import flash.media.SoundChannel;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
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
    * has none, given back after a battle and when the player switches the
    * music on again (SoundManager.switchMusic, the sound switch of the
    * control bar). A battle plays the battle music, looped (the battle module
    * that played it in 2013 is lost; the later client's SoundManager keeps two,
    * music/fightBgMusic0 and 1: 1 is the classic one, the older encoding of
    * the two, 0 a 2019 piece).
    *
    * The 沙盒's rooms play the music their mod gives (docs/MODDING.md): a music
    * file of the game as above, or the mod's own Sound, looped on a channel
    * of its own, stopped by a battle, another room or the sound switch.
    */
   public class SceneMusic
   {
      private var sceneName:String;
      private var fighting:Boolean;
      public static const FIGHT_MUSIC:String = "music/fightBgMusic1.mp3";

      private static var _instance:SceneMusic;
      /** A mod's own music, playing (or held while the switch is off). */
      private var own:Sound;
      private var ownChannel:SoundChannel;
      /** The sound switch has no event for off: looked at while a mod's music plays. */
      private var ownWatch:Timer;

      /** The one SceneInit made (a mod's music() asks it to play the 沙盒 room's again). */
      public static function get instance():SceneMusic
      {
         return _instance;
      }

      public function SceneMusic()
      {
         _instance = this;
         SoundManager.instance.addEventListener(Event.SOUND_COMPLETE, onSoundComplete);
         SoundManager.instance.addEventListener(SoundManagerEvent.ON_SWITCH_ON, onSwitchOn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_START, onFightStart);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
      }

      public function playSceneMusic(name:String):void
      {
         sceneName = name;
         var mine:Sound = name == "sandboxroom" ? modSound() : null;
         if (mine != null)
         {
            SoundManager.instance.stopBackgroundMusic();
            playOwn(mine);
            return;
         }
         stopOwn();
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
         stopOwn();
         sceneName = name;
         if (playingOneOf(files)) return;
         playRandom(files);
      }

      private static function musicOf(name:String):String
      {
         // The 沙盒 room plays the music the mod names for the room shown (docs/MODDING.md).
         if (name == "sandboxroom")
         {
            try { return String(getDefinitionByName("mmo.control.SandboxRun")["music"] || ""); }
            catch (e0:Error) {}
            return "";
         }
         try { return ConfigReader.instance.getSceneMusic(name); }
         catch (e:Error) {}
         return null;
      }

      private static function modSound():Sound
      {
         try { return getDefinitionByName("mmo.control.ModRun")["musicSoundNow"] as Sound; }
         catch (e:Error) {}
         return null;
      }

      private function playOwn(s:Sound):void
      {
         if (s == own && ownChannel != null) return;
         stopOwn();
         own = s;
         if (fighting || SoundManager.instance.isClose) return;
         try { ownChannel = s.play(0, int.MAX_VALUE); }
         catch (e:Error) { RLog.error("mod music", e); }
         RLog.log("music: the mod's own (sandboxroom)");
         if (ownWatch == null)
         {
            ownWatch = new Timer(500);
            ownWatch.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
            {
               if (ownChannel != null && SoundManager.instance.isClose)
               {
                  ownChannel.stop();
                  ownChannel = null;
               }
            });
         }
         ownWatch.start();
      }

      private function stopOwn():void
      {
         if (ownChannel != null) ownChannel.stop();
         ownChannel = null;
         own = null;
         if (ownWatch != null) ownWatch.stop();
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
         if (fighting || own != null) return;
         if (sceneName != null && !SoundManager.instance.isClose) playRandom(musicOf(sceneName) || "");
      }

      private function onSwitchOn(e:SoundManagerEvent):void
      {
         if (fighting) fightMusic();
         else if (sceneName != null) playSceneMusic(sceneName);
      }

      private function onFightStart(e:Event):void
      {
         fighting = true;
         stopOwn();
         SoundManager.instance.stopBackgroundMusic();
         fightMusic();
      }

      private function fightMusic():void
      {
         if (SoundManager.instance.isClose) return;
         RLog.log("music: " + FIGHT_MUSIC + " (battle)");
         SoundManager.instance.playBackgroundMusic(FIGHT_MUSIC, 1, true);
      }

      private function onFightEnd(e:Event):void
      {
         fighting = false;
         SoundManager.instance.stopBackgroundMusic();
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info != null) playSceneMusic(String(info.sceneName));
      }
   }
}
