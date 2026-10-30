package mmo.play.scene
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;

   /** REBUILT. Named art layers every scene symbol carries. */
   public class AbstractScene extends Sprite
   {
      public function AbstractScene()
      {
         super();
      }

      public function get backGround():Sprite
      {
         return getChildByName("background") as Sprite;
      }

      public function get foreGround():Sprite
      {
         return getChildByName("foreground") as Sprite;
      }

      public function get container():Sprite
      {
         return getChildByName("overlap") as Sprite;
      }

      public function get topGround():Sprite
      {
         return getChildByName("topground") as Sprite;
      }

      public function get obStruction():Sprite
      {
         return getChildByName("obstruction") as Sprite;
      }

      /** Scenes cache their still layers as bitmaps (2012/13 scenes call it from cacheSceneLayers). */
      protected function cacheLayer(layer:DisplayObject):void
      {
         if (layer != null) layer.cacheAsBitmap = true;
      }

      /** Where players are placed: the overlap layer, else foreground, else the scene. */
      public function get playerLayer():Sprite
      {
         return container || foreGround || this;
      }
   }
}
