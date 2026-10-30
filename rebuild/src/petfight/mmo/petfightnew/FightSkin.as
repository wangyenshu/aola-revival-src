package mmo.petfightnew
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT. Drawing helpers for the battle screen. The 2012 battle art was
    * in the lost battle module; colours and shapes follow the official
    * screenshots of December 2011 – November 2012 (refs/battle-ui-2011-2012):
    * light blue glass for frames and the command wheel, orange for the chosen
    * command and the HP bar, green for skills, white writing with a dark edge.
    */
   public class FightSkin
   {
      public static const BLUE_EDGE:uint = 0x1E6FA8;
      public static const TEXT_EDGE:uint = 0x15457A;

      public static function vgrad(g:Graphics, w:Number, h:Number, top:uint, bottom:uint, y:Number = 0):void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(w, h, Math.PI / 2, 0, y);
         g.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
      }

      /** White (or coloured) writing with a dark edge, as on the 2012 buttons. */
      public static function label(text:String, size:int, color:uint = 0xFFFFFF, edge:uint = TEXT_EDGE, bold:Boolean = true, align:String = "left", font:String = "黑体"):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat(font, size, color, bold, null, null, null, null, align);
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = align == TextFormatAlign.CENTER ? TextFieldAutoSize.CENTER : (align == TextFormatAlign.RIGHT ? TextFieldAutoSize.RIGHT : TextFieldAutoSize.LEFT);
         t.text = text;
         if (edge != 0xFFFFFFFF) t.filters = [new GlowFilter(edge, 1, 3, 3, 8)];
         return t;
      }

      /** A glass bubble (the command wheel): colours top/bottom, edge colour. */
      public static function bubble(g:Graphics, r:Number, top:uint, bottom:uint, edge:uint):void
      {
         g.clear();
         g.lineStyle(2, edge);
         var m:Matrix = new Matrix();
         m.createGradientBox(r * 2, r * 2, Math.PI / 2, -r, -r);
         g.beginGradientFill(GradientType.LINEAR, [top, bottom], [1, 1], [0, 255], m);
         g.drawCircle(0, 0, r);
         g.endFill();
         g.lineStyle(2, 0xFFFFFF, 0.8);
         g.drawCircle(0, 0, r - 3);
         g.lineStyle();
         m = new Matrix();
         m.createGradientBox(r * 1.4, r, Math.PI / 2, -r * 0.7, -r * 0.92);
         g.beginGradientFill(GradientType.LINEAR, [0xFFFFFF, 0xFFFFFF], [0.85, 0.05], [0, 255], m);
         g.drawEllipse(-r * 0.7, -r * 0.9, r * 1.4, r * 0.9);
         g.endFill();
      }

      /** Light blue glass frame with a white inner line. */
      public static function frame(g:Graphics, x:Number, y:Number, w:Number, h:Number, r:Number = 16):void
      {
         g.lineStyle(2, 0x5AA7D6);
         vgrad(g, w, h, 0xF2FBFF, 0xC6E6F8, y);
         g.drawRoundRect(x, y, w, h, r, r);
         g.endFill();
         g.lineStyle(1.5, 0xFFFFFF, 0.9);
         g.drawRoundRect(x + 3, y + 3, w - 6, h - 6, r - 4, r - 4);
         g.lineStyle();
      }

      /** Dark blue panel (the battle log). */
      public static function darkPanel(g:Graphics, x:Number, y:Number, w:Number, h:Number, r:Number = 14):void
      {
         g.lineStyle(2, 0x7FC6F0);
         vgrad(g, w, h, 0x2453A8, 0x0F2C74, y);
         g.drawRoundRect(x, y, w, h, r, r);
         g.endFill();
         g.lineStyle();
      }

      /** An HP bar: frame w×h, filled to ratio with orange (mine) or red (the other side). */
      public static function hpBar(g:Graphics, w:Number, h:Number, ratio:Number, orange:Boolean = true):void
      {
         g.clear();
         g.lineStyle(1.5, 0x4E8DB8);
         vgrad(g, w, h, 0xF6FBFF, 0xD3E8F5);
         g.drawRoundRect(0, 0, w, h, h, h);
         g.endFill();
         g.lineStyle();
         var r:Number = Math.max(0, Math.min(1, ratio));
         if (r <= 0) return;
         var fw:Number = Math.max(h - 4, (w - 4) * r);
         var c:Array = orange ? (r > 0.2 ? [0xFFD86B, 0xFF8418] : [0xFF8A7A, 0xD0281E]) : (r > 0.2 ? [0xFF9A6B, 0xE0401E] : [0xFF6A6A, 0xB0101E]);
         var m:Matrix = new Matrix();
         m.createGradientBox(fw, h - 4, Math.PI / 2, 2, 2);
         g.beginGradientFill(GradientType.LINEAR, c, [1, 1], [0, 255], m);
         g.drawRoundRect(2, 2, fw, h - 4, h - 4, h - 4);
         g.endFill();
         g.beginFill(0xFFFFFF, 0.35);
         g.drawRoundRect(4, 3, Math.max(0, fw - 4), (h - 4) / 2 - 1, h / 2, h / 2);
         g.endFill();
      }

      /** The orange LV badge. */
      public static function lvBadge(level:int):Sprite
      {
         var s:Sprite = new Sprite();
         var g:Graphics = s.graphics;
         g.lineStyle(2, 0xFFFFFF);
         var m:Matrix = new Matrix();
         m.createGradientBox(28, 28, Math.PI / 2, -14, -14);
         g.beginGradientFill(GradientType.LINEAR, [0xFFB04A, 0xE2560F], [1, 1], [0, 255], m);
         g.drawCircle(0, 0, 14);
         g.endFill();
         var lv:TextField = label("LV", 8, 0xFFFFFF, 0x9A3A00, true, TextFormatAlign.CENTER, "Arial");
         lv.x = -lv.width / 2;
         lv.y = -13;
         s.addChild(lv);
         var n:TextField = label(String(level), 11, 0xFFFFFF, 0x9A3A00, true, TextFormatAlign.CENTER, "Arial");
         n.name = "lv";
         n.x = -n.width / 2;
         n.y = -4;
         s.addChild(n);
         s.mouseEnabled = s.mouseChildren = false;
         return s;
      }

      /** petattribute/attribute<n>.swf: mmo.pet.attribute<n> (the 2011 attribute icons), scaled into a box. */
      public static function attributeIcon(into:DisplayObjectContainer, attr:int, box:int):void
      {
         var cls:String = "mmo.pet.attribute" + attr;
         var put:Function = function(... a):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var d:DisplayObject = new C() as DisplayObject;
            var b:Object = d.getBounds(d);
            var k:Number = Math.min(box / Math.max(1, b.width), box / Math.max(1, b.height));
            d.scaleX = d.scaleY = k;
            d.x = -(b.left + b.width / 2) * k;
            d.y = -(b.top + b.height / 2) * k;
            while (into.numChildren) into.removeChildAt(0);
            into.addChild(d);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("petattribute/attribute" + attr, put, cls, function(e:* = null):void {});
      }

      /** item/view<id>.swf: mmo.item.view<id> (what the 2013 ItemViewCreator loads), fitted into a box. */
      public static function itemIcon(into:DisplayObjectContainer, id:int, box:int):void
      {
         var cls:String = "mmo.item.view" + id;
         var put:Function = function(... a):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var d:DisplayObject = new C() as DisplayObject;
            var b:Object = d.getBounds(d);
            var k:Number = Math.min(1.2, box / Math.max(1, b.width), box / Math.max(1, b.height));
            d.scaleX = d.scaleY = k;
            d.x = -(b.left + b.width / 2) * k;
            d.y = -(b.top + b.height / 2) * k;
            while (into.numChildren) into.removeChildAt(0);
            into.addChild(d);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("item/view" + id, put, cls, function(e:* = null):void {});
      }

      /** peticon<race>_S fitted into a circle of the given size. */
      public static function petIcon(into:DisplayObjectContainer, race:int, size:int, large:Boolean = false):void
      {
         var cls:String = "mmo.pet.peticon" + race + (large ? "_L" : "_S");
         var put:Function = function(... a):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var pic:DisplayObject = new C() as DisplayObject;
            var b:Object = pic.getBounds(pic);
            var k:Number = Math.min(1.3, size / Math.max(1, b.width), size / Math.max(1, b.height));
            pic.scaleX = pic.scaleY = k;
            pic.x = -(b.left + b.width / 2) * k;
            pic.y = -(b.top + b.height / 2) * k;
            while (into.numChildren) into.removeChildAt(0);
            into.addChild(pic);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + race, put, cls, function(e:* = null):void {});
      }

      public static function shadow():DropShadowFilter
      {
         return new DropShadowFilter(2, 90, 0x0B2F4A, 0.5, 4, 4, 1);
      }
   }
}
