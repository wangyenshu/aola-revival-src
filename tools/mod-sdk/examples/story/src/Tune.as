package
{
   import mx.core.SoundAsset;

   /**
    * The mod's own music, an MP3 embedded in the mod (art/make_tune.py made it).
    * The class itself carries the [Embed]: an embed on a variable would put the
    * file into the SWF twice with this compiler.
    */
   [Embed(source="../art/tune.mp3")]
   public class Tune extends SoundAsset
   {
   }
}
