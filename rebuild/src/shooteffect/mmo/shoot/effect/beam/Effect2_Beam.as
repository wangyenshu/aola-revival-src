package mmo.shoot.effect.beam
{
   import flash.display.MovieClip;
   import flash.media.Sound;
   import mmo.common.sound.SoundPlayer;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.music.IMusic;
   import mmo.interfaces.shoot.effects.IBeamEffectWithSound;
   
   public class Effect2_Beam extends MovieClip implements IBeamEffectWithSound
   {
      
      private var isInit:Boolean;
      
      public function Effect2_Beam()
      {
         super();
      }
      
      public function initSound() : void
      {
         var _loc1_:IMusic = null;
         var _loc2_:Sound = null;
         var _loc3_:SoundPlayer = null;
         if(!this.isInit)
         {
            _loc1_ = ServiceContainer.getService("MusicService") as IMusic;
            _loc2_ = _loc1_.getMusicByName("x5008") as Sound;
            _loc3_ = new SoundPlayer(_loc2_);
            _loc3_.play();
            this.isInit = true;
         }
      }
   }
}

