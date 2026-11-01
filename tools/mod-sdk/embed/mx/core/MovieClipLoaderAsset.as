package mx.core
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;

   /**
    * REVIVAL (docs/MODDING.md). The base of a whole embedded SWF ([Embed] of a
    * .swf with no symbol): the compiler's subclass gives its bytes
    * (movieClipData), which are shown here once loaded (Event.COMPLETE).
    */
   public class MovieClipLoaderAsset extends MovieClip
   {
      protected var initialWidth:Number = 0;
      protected var initialHeight:Number = 0;
      private var loader:Loader;

      public function MovieClipLoaderAsset()
      {
         super();
         var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));
         context.allowCodeImport = true;
         loader = new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void { dispatchEvent(new Event(Event.COMPLETE)); });
         var bytes:ByteArray = movieClipData;
         if (bytes != null) loader.loadBytes(bytes, context);
         addChild(loader);
      }

      /** The SWF's bytes (the compiler's subclass gives them). */
      public function get movieClipData():ByteArray
      {
         return null;
      }

      override public function get width():Number
      {
         return initialWidth > 0 && loader.content == null ? initialWidth : super.width;
      }

      override public function get height():Number
      {
         return initialHeight > 0 && loader.content == null ? initialHeight : super.height;
      }
   }
}
