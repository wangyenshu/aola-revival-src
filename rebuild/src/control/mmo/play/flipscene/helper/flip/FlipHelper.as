package mmo.play.flipscene.helper.flip
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.interfaces.IDispose;

   /** REBUILT. Turns scene layers upside down (scaleY -1 over the 560 px stage). */
   public class FlipHelper implements IDispose
   {
      private var layers:Array = [];
      private var _bActive:Boolean;

      public function FlipHelper()
      {
         super();
      }

      public function get bActive():Boolean
      {
         return _bActive;
      }

      public function addLayer(layer:Sprite):void
      {
         if (layer == null || layers.indexOf(layer) >= 0) return;
         layers.push(layer);
         if (_bActive) flip(layer);
      }

      public function removeLayer(layer:Sprite):void
      {
         var i:int = layers.indexOf(layer);
         if (i >= 0) layers.splice(i, 1);
      }

      public function activeFlip():void
      {
         if (_bActive) return;
         _bActive = true;
         for each (var d:DisplayObject in layers) flip(d);
      }

      public function deactiveFlip():void
      {
         if (!_bActive) return;
         _bActive = false;
         for each (var d:DisplayObject in layers) flip(d);
      }

      private static function flip(d:DisplayObject):void
      {
         d.scaleY = -d.scaleY;
         d.y = d.scaleY < 0 ? d.y + 560 : d.y - 560;
      }

      public function dispose():void
      {
         layers = [];
         _bActive = false;
      }
   }
}
