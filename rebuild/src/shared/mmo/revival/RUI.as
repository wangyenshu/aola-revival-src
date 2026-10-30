package mmo.revival
{
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.FocusEvent;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;

   /**
    * REBUILT panels' look (not of 2013): the light blue rounded panel with a
    * blue rim, the red round close button and the orange buttons the rebuilt
    * player card already uses, after the panels of the era client.
    */
   public class RUI
   {
      public static const BLUE:uint = 0x1A5FA8;

      /** A panel of w x h: gradient box, rim, shadow, title; the close button named closeName calls onClose. */
      public static function panel(w:int, h:int, title:String, onClose:Function, closeName:String = "panelClose"):Sprite
      {
         var box:Sprite = new Sprite();
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2);
         box.graphics.lineStyle(3, 0x2E86D6);
         box.graphics.beginGradientFill(GradientType.LINEAR, [0xEAF7FF, 0xBFE3FA], [1, 1], [0, 255], m);
         box.graphics.drawRoundRect(0, 0, w, h, 26, 26);
         box.graphics.endFill();
         box.filters = [new DropShadowFilter(4, 90, 0, 0.45, 10, 10)];
         box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         box.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         if (title)
         {
            var band:Shape = new Shape();
            var bm:Matrix = new Matrix();
            bm.createGradientBox(w - 24, 34, Math.PI / 2);
            band.graphics.beginGradientFill(GradientType.LINEAR, [0x5FB6F2, 0x2E86D6], [1, 1], [0, 255], bm);
            band.graphics.drawRoundRect(12, 10, w - 24, 34, 18, 18);
            band.graphics.endFill();
            box.addChild(band);
            var t:TextField = text(17, 0xFFFFFF, true);
            t.text = title;
            t.x = (w - t.width) / 2;
            t.y = 15;
            t.filters = [new GlowFilter(0x0D4D8C, 1, 3, 3, 4)];
            box.addChild(t);
         }
         var closeBtn:Sprite = new Sprite();
         closeBtn.name = closeName;
         closeBtn.buttonMode = true;
         closeBtn.graphics.lineStyle(2.5, 0xFFFFFF);
         closeBtn.graphics.beginFill(0xD9452B);
         closeBtn.graphics.drawCircle(0, 0, 14);
         closeBtn.graphics.endFill();
         closeBtn.graphics.lineStyle(3, 0xFFFFFF);
         closeBtn.graphics.moveTo(-5, -5);
         closeBtn.graphics.lineTo(5, 5);
         closeBtn.graphics.moveTo(5, -5);
         closeBtn.graphics.lineTo(-5, 5);
         closeBtn.x = w - 6;
         closeBtn.y = 6;
         closeBtn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (onClose != null) onClose();
         });
         box.addChild(closeBtn);
         return box;
      }

      /** A white rounded area for lists inside a panel. */
      public static function well(x:Number, y:Number, w:Number, h:Number):Shape
      {
         var s:Shape = new Shape();
         s.graphics.lineStyle(1.5, 0x8CC8F0);
         s.graphics.beginFill(0xFFFFFF, 0.8);
         s.graphics.drawRoundRect(x, y, w, h, 18, 18);
         s.graphics.endFill();
         return s;
      }

      /** An orange (or other colour) glossy button. */
      public static function button(label:String, f:Function, w:int = 80, h:int = 28, top:uint = 0xFFC45A, bottom:uint = 0xF07812, name:String = null):Sprite
      {
         var b:Sprite = new Sprite();
         if (name) b.name = name;
         b.buttonMode = true;
         b.mouseChildren = false;
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2);
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
         b.graphics.drawRoundRect(0, 0, w, h, h, h);
         b.graphics.endFill();
         b.graphics.lineStyle();
         b.graphics.beginFill(0xFFFFFF, 0.35);
         b.graphics.drawRoundRect(4, 2, w - 8, h / 2 - 1, h / 2, h / 2);
         b.graphics.endFill();
         b.filters = [new DropShadowFilter(1.5, 90, 0x0B3F70, 0.4, 3, 3, 1)];
         var t:TextField = text(13, 0xFFFFFF, true);
         t.text = label;
         t.filters = [new GlowFilter(0x9C4A00, 1, 2, 2, 4)];
         t.x = (w - t.width) / 2;
         t.y = (h - t.height) / 2;
         b.addChild(t);
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { b.alpha = 0.85; });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { b.alpha = 1; });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (f != null) f();
         });
         return b;
      }

      /** A blue small button (◀ ▶ and the like). */
      public static function smallButton(label:String, f:Function, w:int = 34, h:int = 24, name:String = null):Sprite
      {
         return button(label, f, w, h, 0x6CC0F5, 0x2E86D6, name);
      }

      /** A text box to type into: digits only when restrict is "0-9". */
      public static function input(w:int, value:String = "", restrict:String = null, maxChars:int = 9, name:String = null):TextField
      {
         var t:TextField = new TextField();
         if (name) t.name = name;
         t.type = TextFieldType.INPUT;
         t.defaultTextFormat = new TextFormat("SimSun", 14, 0x1A3A5A, true);
         t.border = true;
         t.borderColor = 0x5FA8E0;
         t.background = true;
         t.backgroundColor = 0xFFFFFF;
         t.width = w;
         t.height = 22;
         t.maxChars = maxChars;
         if (restrict) t.restrict = restrict;
         t.text = value;
         t.addEventListener(FocusEvent.FOCUS_IN, function(e:FocusEvent):void { t.setSelection(0, t.length); });
         t.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         return t;
      }

      public static function text(size:int, color:uint, bold:Boolean, wrap:int = 0):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.selectable = false;
         t.mouseEnabled = false;
         if (wrap > 0)
         {
            t.multiline = true;
            t.wordWrap = true;
            t.width = wrap;
         }
         else
         {
            t.autoSize = TextFieldAutoSize.LEFT;
         }
         return t;
      }

      /** The dimmed screen behind a panel; a click on it calls onClick. */
      public static function dim(onClick:Function = null):Sprite
      {
         var d:Sprite = new Sprite();
         d.graphics.beginFill(0x000000, 0.3);
         d.graphics.drawRect(0, 0, 960, 560);
         d.graphics.endFill();
         d.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         d.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (onClick != null) onClick();
         });
         return d;
      }
   }
}
