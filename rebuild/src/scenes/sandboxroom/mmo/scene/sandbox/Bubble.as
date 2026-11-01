package mmo.scene.sandbox
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.revival.RUI;

   /** REVIVAL. A speech bubble (its tail's tip at 0, 0), as the scenes' talk bubbles. */
   public class Bubble
   {
      public static function make(text:String):Sprite
      {
         var s:Sprite = new Sprite();
         s.mouseEnabled = s.mouseChildren = false;
         // One line as long as it is, wrapped at 170 (autoSize keeps the height to the text).
         var t:TextField = RUI.text(12, 0x333333, false);
         t.text = text;
         if (t.width > 174)
         {
            t.multiline = true;
            t.wordWrap = true;
            t.width = 170;
         }
         t.width = Math.max(30, t.width);
         var w:Number = t.width + 16, h:Number = t.height + 10;
         s.graphics.lineStyle(2, 0x333333);
         s.graphics.beginFill(0xFFFFFF);
         s.graphics.drawRoundRect(-w / 2, -h - 10, w, h, 14, 14);
         s.graphics.endFill();
         s.graphics.lineStyle();
         s.graphics.beginFill(0xFFFFFF);
         s.graphics.moveTo(-7, -11);
         s.graphics.lineTo(0, 0);
         s.graphics.lineTo(7, -11);
         s.graphics.endFill();
         s.graphics.lineStyle(2, 0x333333);
         s.graphics.moveTo(-7, -10);
         s.graphics.lineTo(0, 0);
         s.graphics.lineTo(7, -10);
         t.x = -w / 2 + 8;
         t.y = -h - 5;
         s.addChild(t);
         return s;
      }
   }
}
