package mx.core
{
   import flash.media.Sound;
   import flash.media.SoundLoaderContext;
   import flash.net.URLRequest;

   /** REVIVAL (docs/MODDING.md). The base of an embedded MP3 ([Embed] of an .mp3): a Sound. */
   public class SoundAsset extends Sound
   {
      public function SoundAsset(stream:URLRequest = null, context:SoundLoaderContext = null)
      {
         super(stream, context);
      }
   }
}
