package mmo.scene.cloudstar1
{
   import flash.display.Sprite;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;

   /** REBUILT: a drawn map button (a rolled map under the golden wings of 云端王国's emblem). */
   public class MapButton
   {
      public static function make(label:String):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = "btnMap";
         b.buttonMode = true;
         b.mouseChildren = false;
         var g:* = b.graphics;
         // Wings.
         g.lineStyle(2, 0xB8860B);
         g.beginFill(0xFFE27A);
         g.moveTo(-6, -18); g.curveTo(-34, -40, -46, -12); g.curveTo(-30, -20, -24, -6); g.lineTo(-6, -6); g.lineTo(-6, -18);
         g.moveTo(6, -18); g.curveTo(34, -40, 46, -12); g.curveTo(30, -20, 24, -6); g.lineTo(6, -6); g.lineTo(6, -18);
         g.endFill();
         // The map scroll.
         g.lineStyle(2, 0x7A5222);
         g.beginFill(0xFFF6D6);
         g.drawRoundRect(-26, -14, 52, 38, 10, 10);
         g.endFill();
         g.lineStyle(2, 0x4E9DE0);
         g.moveTo(-18, 10); g.curveTo(-8, -6, 0, 6); g.curveTo(8, 16, 18, -2);
         g.lineStyle();
         g.beginFill(0xE23B3B);
         g.drawCircle(12, 0, 4);
         g.endFill();
         var t:TextField = new TextField();
         var f:TextFormat = new TextFormat("SimSun", 12, 0xFFFFFF, true);
         f.align = TextFormatAlign.CENTER;
         t.defaultTextFormat = f;
         t.selectable = false;
         t.width = 96;
         t.height = 18;
         t.x = -48;
         t.y = 26;
         t.text = label;
         t.filters = [new GlowFilter(0x1E4E8C, 1, 3, 3, 8)];
         b.addChild(t);
         b.filters = [new GlowFilter(0xFFFFFF, 0.9, 6, 6, 2)];
         return b;
      }
   }
}
