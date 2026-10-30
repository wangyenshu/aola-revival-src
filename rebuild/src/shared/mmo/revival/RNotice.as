package mmo.revival
{
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Timer;

   /**
    * REBUILT helper (not an original class): a short message in the middle of
    * the stage, for places the revival cannot do what the 2013 game did.
    */
   public class RNotice
   {
      private static var box:Sprite;
      private static var timer:Timer;

      public static function show(parent:DisplayObjectContainer, text:String, seconds:Number = 3):void
      {
         if (parent == null) return;
         hide();
         box = new Sprite();
         box.mouseEnabled = box.mouseChildren = false;
         var tf:TextField = new TextField();
         tf.defaultTextFormat = new TextFormat("SimSun", 14, 0xFFFFFF, true);
         tf.autoSize = TextFieldAutoSize.LEFT;
         tf.selectable = false;
         tf.text = text;
         tf.filters = [new GlowFilter(0x000000, 0.8, 2, 2, 4)];
         box.graphics.beginFill(0x10305A, 0.85);
         box.graphics.lineStyle(2, 0x7FD4FF);
         box.graphics.drawRoundRect(0, 0, tf.width + 32, tf.height + 20, 16, 16);
         box.graphics.endFill();
         tf.x = 16;
         tf.y = 10;
         box.addChild(tf);
         box.x = Math.round((960 - box.width) / 2);
         box.y = 220;
         parent.addChild(box);
         timer = new Timer(seconds * 1000, 1);
         timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { hide(); });
         timer.start();
      }

      public static function hide():void
      {
         if (timer) timer.stop();
         timer = null;
         if (box && box.parent) box.parent.removeChild(box);
         box = null;
      }
   }
}
