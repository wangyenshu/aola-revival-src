package mmo.game.flyingfruit.sound
{
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import mmo.common.sound.SoundManager;
   import mmo.common.sound.SoundPlayer;
   
   public class SongController
   {
      
      private static var _instance:SongController;
      
      private var shootSound:SoundPlayer;
      
      private var hitFlyingDiskSound:SoundPlayer;
      
      private var hitDiskSound:SoundPlayer;
      
      private var hitClockSound:SoundPlayer;
      
      private var hitBombSound:SoundPlayer;
      
      private var hitDimandSound:SoundPlayer;
      
      private var bombSound:SoundPlayer;
      
      private var countDownSound:SoundPlayer;
      
      private var diskAppearSound:SoundPlayer;
      
      private var diskAppearSound2:SoundPlayer;
      
      private var beginSound:SoundPlayer;
      
      private var bgSound:SoundPlayer;
      
      private var isClose:Boolean;
      
      private var sceneSoundName:String;
      
      private var playSignal:Boolean = true;
      
      public function SongController()
      {
         super();
         if(_instance != null)
         {
            throw new Error("error in GameSoundManager");
         }
         this.init();
      }
      
      public static function getInstance() : SongController
      {
         if(_instance == null)
         {
            _instance = new SongController();
         }
         return _instance;
      }
      
      public static function dispose() : void
      {
         SongController.getInstance().setCountDownSoundStop();
         SongController.getInstance().setBGSoundStop();
         SongController.getInstance().resetSceneBgSound();
         _instance = null;
      }
      
      private function init() : void
      {
         this.isClose = SoundManager.instance.isClose;
         this.sceneSoundName = SoundManager.instance.currentMusic;
         this.shootSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.ShootSound"));
         this.hitFlyingDiskSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.HitFlyingDiskSound"));
         this.hitDiskSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.HitDiskSound"));
         this.hitClockSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.HitClockSound"));
         this.hitBombSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.HitBombSound"));
         this.hitDimandSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.HitDimandSound"));
         this.bombSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.BombSound"));
         this.countDownSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.CountDownSound"));
         this.diskAppearSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.DiskAppearSound"));
         this.diskAppearSound2 = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.DiskAppearSound2"));
         this.beginSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.BeginSound"));
         this.bgSound = new SoundPlayer(this.getSound("mmo.game.flyingfruit.sound.BGSound"));
      }
      
      public function stopSceneBgSound() : void
      {
         if(this.isClose)
         {
            return;
         }
         SoundManager.instance.stopBackgroundMusic();
      }
      
      public function resetSceneBgSound() : void
      {
         if(this.isClose || this.sceneSoundName == null || this.sceneSoundName.length == 0)
         {
            return;
         }
         SoundManager.instance.playBackgroundMusic(this.sceneSoundName);
      }
      
      public function playShootSound() : void
      {
         this.setSoundPlay(this.shootSound);
      }
      
      public function playHitFlyingDiskSound() : void
      {
         this.setSoundPlay(this.hitFlyingDiskSound);
      }
      
      public function playHitDiskSound() : void
      {
         this.setSoundPlay(this.hitDiskSound);
      }
      
      public function playHitClockSound() : void
      {
         this.setSoundPlay(this.hitClockSound);
      }
      
      public function playHitBombSound() : void
      {
         this.setSoundPlay(this.hitBombSound);
      }
      
      public function playHitDimandSound() : void
      {
         this.setSoundPlay(this.hitDimandSound);
      }
      
      public function playBombSound() : void
      {
         this.setSoundPlay(this.bombSound);
      }
      
      public function playCountDownSound() : void
      {
         this.setSoundPlay(this.countDownSound);
      }
      
      public function setCountDownSoundStop() : void
      {
         if(this.isClose)
         {
            return;
         }
         this.countDownSound.stop();
      }
      
      public function playDiskAppearSound() : void
      {
         if(this.playSignal)
         {
            this.setSoundPlay(this.diskAppearSound);
            this.playSignal = false;
         }
         else
         {
            this.playSignal = true;
            this.setSoundPlay(this.diskAppearSound2);
         }
      }
      
      public function playBeginSound() : void
      {
         this.setSoundPlay(this.beginSound);
      }
      
      public function playBGSound() : void
      {
         if(this.isClose)
         {
            return;
         }
         this.bgSound.play(true);
      }
      
      public function setBGSoundStop() : void
      {
         if(this.isClose)
         {
            return;
         }
         this.bgSound.stop();
      }
      
      private function setSoundPlay(param1:SoundPlayer) : void
      {
         if(this.isClose)
         {
            return;
         }
         param1.play();
      }
      
      private function setSoundStop(param1:SoundPlayer) : void
      {
         if(this.isClose)
         {
            param1.stop();
         }
      }
      
      private function getSound(param1:String) : Sound
      {
         var _loc2_:Class = ApplicationDomain.currentDomain.getDefinition(param1) as Class;
         return new _loc2_() as Sound;
      }
   }
}

