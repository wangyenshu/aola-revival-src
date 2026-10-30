package mmo.shoot.effect.beam
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.media.Sound;
   import mmo.common.sound.SoundPlayer;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.music.IMusic;
   import mmo.interfaces.shoot.effects.IBeamEffectWithSound;
   
   public class Collect149_Beam extends MovieClip implements IBeamEffectWithSound
   {
      
      internal var soundplayer:SoundPlayer;
      
      private var isInit:Boolean;
      
      public function Collect149_Beam()
      {
         super();
      }
      
      public function initSound() : void
      {
         var _loc1_:IMusic = null;
         var _loc2_:Sound = null;
         if(!this.isInit)
         {
            this.addEventListener(Event.REMOVED_FROM_STAGE,this.sound_stop);
            _loc1_ = ServiceContainer.getService("MusicService") as IMusic;
            _loc2_ = _loc1_.getMusicByName("x5006") as Sound;
            this.soundplayer = new SoundPlayer(_loc2_);
            this.soundplayer.play(true,2);
            this.isInit = true;
         }
      }
      
      private function sound_stop(param1:Event) : void
      {
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.sound_stop);
         if(this.soundplayer != null)
         {
            this.soundplayer.stop();
         }
      }
   }
}

