package mx.core
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;

   /**
    * REVIVAL (docs/MODDING.md). The class the compiler bases an embedded
    * picture on ([Embed] of a PNG, JPEG or GIF): a Bitmap. Named as the Flex
    * SDK's, which the compiler asks for; mods need no more than this.
    */
   public class BitmapAsset extends Bitmap
   {
      public function BitmapAsset(bitmapData:BitmapData = null, pixelSnapping:String = "auto", smoothing:Boolean = false)
      {
         super(bitmapData, pixelSnapping, smoothing);
      }
   }
}
