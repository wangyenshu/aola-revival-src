package mmo.petfightnew
{
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;

   /**
    * REBUILT. A button of the battle panels, drawn after the light blue
    * buttons of the 2013 pet/fightpreview art (white to sky blue, a darker blue
    * edge, dark teal writing). A skill button carries a second line (PP) and
    * the colour of its attribute along the left.
    */
   public class FightButton extends Sprite
   {
      private var face:Shape = new Shape();
      private var label:TextField = new TextField();
      private var sub:TextField;
      private var w:int;
      private var h:int;
      private var stripe:int;
      private var _enabled:Boolean = true;
      private var over:Boolean;
      public var data:Object;

      private var orange:Boolean;

      public function FightButton(text:String, w:int, h:int, size:int = 13, subText:String = null, stripe:int = -1, orange:Boolean = false)
      {
         super();
         this.w = w;
         this.h = h;
         this.stripe = stripe;
         this.orange = orange;
         addChild(face);
         label.defaultTextFormat = new TextFormat("黑体", size, orange ? 0xFFFFFF : 0x0B4E54, true, null, null, null, null, TextFormatAlign.CENTER);
         if (orange) label.filters = [new GlowFilter(0x9A3A00, 1, 3, 3, 8)];
         label.selectable = false;
         label.mouseEnabled = false;
         label.width = w - (stripe >= 0 ? 10 : 0);
         label.x = stripe >= 0 ? 8 : 0;
         label.text = text;
         label.height = label.textHeight + 4;
         addChild(label);
         if (subText != null)
         {
            sub = new TextField();
            sub.defaultTextFormat = new TextFormat("宋体", 11, 0x2A6F8A, false, null, null, null, null, TextFormatAlign.CENTER);
            sub.selectable = false;
            sub.mouseEnabled = false;
            sub.width = label.width;
            sub.x = label.x;
            sub.text = subText;
            sub.height = sub.textHeight + 4;
            addChild(sub);
            label.y = (h - label.height - sub.height) / 2 + 1;
            sub.y = label.y + label.height - 3;
         }
         else
         {
            label.y = (h - label.height) / 2;
         }
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { over = true; draw(); });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { over = false; draw(); });
         draw();
      }

      public function set text(v:String):void
      {
         label.text = v;
      }

      public function set subText(v:String):void
      {
         if (sub) sub.text = v;
      }

      public function get enabled():Boolean
      {
         return _enabled;
      }

      public function set enabled(v:Boolean):void
      {
         _enabled = v;
         mouseEnabled = v;
         buttonMode = v;
         alpha = v ? 1 : 0.5;
         draw();
      }

      private function draw():void
      {
         var g:* = face.graphics;
         g.clear();
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2);
         var top:uint = orange ? (over && _enabled ? 0xFFE9A8 : 0xFFD27A) : (over && _enabled ? 0xFFFFFF : 0xF0FAFF);
         var bottom:uint = orange ? (over && _enabled ? 0xF7941E : 0xEC7410) : (over && _enabled ? 0xA9DCF2 : 0x86C6E6);
         g.lineStyle(1.5, orange ? 0xB24A00 : 0x3A8FB7);
         g.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
         g.drawRoundRect(0, 0, w, h, orange ? h : 10, orange ? h : 10);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.45);
         g.drawRoundRect(3, 2, w - 6, h / 2 - 2, 8, 8);
         g.endFill();
         if (stripe >= 0)
         {
            g.beginFill(stripe);
            g.drawRoundRect(3, 3, 6, h - 6, 4, 4);
            g.endFill();
         }
      }
   }
}
