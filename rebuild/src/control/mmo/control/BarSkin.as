package mmo.control
{
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;

   /**
    * REBUILT. Drawing helpers for the control bar and its pop-ups. The 2013
    * bar art was in the lost control/control.swf; colours follow the official
    * screenshot of the bar of December 2011 (refs/battle-ui-2011-2012,
    * 1324027054208_1.jpg): light blue glass, white writing with a blue edge.
    */
   public class BarSkin
   {
      public static const EDGE:uint = 0x1C5DA6;

      public static function vgrad(g:Graphics, w:Number, h:Number, colors:Array, y:Number = 0, alphas:Array = null, ratios:Array = null):void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(Math.max(1, w), Math.max(1, h), Math.PI / 2, 0, y);
         if (alphas == null) { alphas = []; for (var i:int = 0; i < colors.length; i++) alphas.push(1); }
         if (ratios == null)
         {
            ratios = [];
            for (var j:int = 0; j < colors.length; j++) ratios.push(colors.length == 1 ? 0 : Math.round(255 * j / (colors.length - 1)));
         }
         g.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, m);
      }

      /** White writing with a blue edge, as under the 2011 bar icons. */
      public static function label(text:String, size:int = 12, color:uint = 0xFFFFFF, edge:uint = EDGE, bold:Boolean = true, font:String = "黑体"):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat(font, size, color, bold);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = text;
         if (edge != 0xFFFFFFFF) t.filters = [new GlowFilter(edge, 1, 3, 3, 10)];
         return t;
      }

      /** A glossy ball: gradient top → bottom, a rim, a white shine. */
      public static function ball(g:Graphics, cx:Number, cy:Number, r:Number, top:uint, bottom:uint, rim:uint = 0xFFFFFF, rimWidth:Number = 1.5):void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(r * 2, r * 2, Math.PI / 2, cx - r, cy - r);
         g.lineStyle(rimWidth, rim);
         g.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
         g.drawCircle(cx, cy, r);
         g.endFill();
         g.lineStyle();
         shine(g, cx, cy - r * 0.42, r * 1.2, r * 0.75);
      }

      /** The white shine in the top half of a glossy shape. */
      public static function shine(g:Graphics, cx:Number, cy:Number, w:Number, h:Number, a:Number = 0.75):void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2, cx - w / 2, cy - h / 2);
         g.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [a, 0.04], [0, 255], m);
         g.drawEllipse(cx - w / 2, cy - h / 2, w, h);
         g.endFill();
      }

      /** Light blue glass panel with a white inner line (the pop-ups). */
      public static function panel(g:Graphics, x:Number, y:Number, w:Number, h:Number, r:Number = 16):void
      {
         g.lineStyle(2, 0x3F8FCB);
         vgrad(g, w, h, [0xF4FCFF, 0xCDEBFA, 0xA9DAF3], y);
         g.drawRoundRect(x, y, w, h, r, r);
         g.endFill();
         g.lineStyle(1.5, 0xFFFFFF, 0.9);
         g.drawRoundRect(x + 3, y + 3, w - 6, h - 6, r - 4, r - 4);
         g.lineStyle();
      }

      /** A small light blue cloud (under the 发言 and 背包 icons). */
      public static function cloud(g:Graphics, cx:Number, cy:Number, w:Number):void
      {
         g.lineStyle(1, 0x6FB9E2);
         g.beginFill(0xD7F3FF);
         g.drawEllipse(cx - w / 2, cy - w * 0.12, w * 0.45, w * 0.26);
         g.drawEllipse(cx + w * 0.05, cy - w * 0.12, w * 0.45, w * 0.26);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xD7F3FF);
         g.drawEllipse(cx - w * 0.3, cy - w * 0.2, w * 0.6, w * 0.34);
         g.endFill();
      }

      public static function star(g:Graphics, cx:Number, cy:Number, r:Number, inner:Number):void
      {
         for (var i:int = 0; i <= 10; i++)
         {
            var a:Number = -Math.PI / 2 + i * Math.PI / 5;
            var rr:Number = i % 2 == 0 ? r : inner;
            var px:Number = cx + Math.cos(a) * rr, py:Number = cy + Math.sin(a) * rr;
            if (i == 0) g.moveTo(px, py); else g.lineTo(px, py);
         }
      }
   }
}
