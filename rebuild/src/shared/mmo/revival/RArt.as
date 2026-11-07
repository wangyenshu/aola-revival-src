package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REVIVAL. Pictures the rebuilt panels put in their boxes: a 亚比's picture
    * (peticon/peticon<id>.swf, mmo.pet.peticon<id>_S or _L) and a 属性's icon
    * (petattribute/attribute<n>.swf, mmo.pet.attribute<n>, the 2011 icons of 0–21;
    * the later 属性 the tools give get a round badge with their name, as the
    * battle screen draws them).
    */
   public class RArt
   {
      private static const LATER_NAMES:Object = {23: "超数码", 24: "超木", 25: "超水", 26: "超火", 27: "超土", 28: "超电", 29: "超光", 30: "超暗",
         31: "超龙", 32: "超上古", 33: "超圣灵", 34: "超王", 999: "超"};

      /** A 亚比's picture centred on into's origin, at most `fit` wide and high ("_S" small, "_L" large). */
      public static function pet(into:DisplayObjectContainer, viewId:int, fit:int, size:String = "_S"):void
      {
         var cls:String = "mmo.pet.peticon" + viewId + size;
         var put:Function = function(d:* = null):void
         {
            if (!RDef.has(cls)) return;
            var pic:DisplayObject = RPetIcon.make(cls);
            if (pic == null) return;
            var b:Object = pic.getBounds(pic);
            var k:Number = Math.min(size == "_L" ? 2 : 1.2, fit / Math.max(1, b.width), fit / Math.max(1, b.height));
            pic.scaleX = pic.scaleY = k;
            pic.x = -(b.left + b.width / 2) * k;
            pic.y = -(b.top + b.height / 2) * k;
            while (into.numChildren) into.removeChildAt(0);
            into.addChild(pic);
         };
         while (into.numChildren) into.removeChildAt(0);
         if (viewId <= 0) return;
         if (RDef.has(cls)) put();
         // Without a class name: a missing one would leave the 2013 ResScheduler's loader taken.
         else ResScheduler.getResource("peticon/peticon" + viewId, put, "", function(e:* = null):void {});
      }

      /** A 属性's icon centred on into's origin, scaled into a box. */
      public static function attribute(into:DisplayObjectContainer, attr:int, box:int):void
      {
         var cls:String = "mmo.pet.attribute" + attr;
         var put:Function = function(d:* = null):void
         {
            if (!RDef.has(cls)) return;
            var C:Class = RDef.get(cls);
            var pic:DisplayObject = new C() as DisplayObject;
            var b:Object = pic.getBounds(pic);
            var k:Number = Math.min(box / Math.max(1, b.width), box / Math.max(1, b.height));
            pic.scaleX = pic.scaleY = k;
            pic.x = -(b.left + b.width / 2) * k;
            pic.y = -(b.top + b.height / 2) * k;
            while (into.numChildren) into.removeChildAt(0);
            into.addChild(pic);
         };
         while (into.numChildren) into.removeChildAt(0);
         if (RDef.has(cls)) put();
         else if (attr >= 0 && attr <= 21) ResScheduler.getResource("petattribute/attribute" + attr, put, "", function(e:* = null):void {});
         else badge(into, attr, box);
      }

      private static function badge(into:DisplayObjectContainer, attr:int, box:int):void
      {
         var name:String = LATER_NAMES[attr] ? String(LATER_NAMES[attr]) : "";
         if (!name) return;
         var r:Number = box / 2 - 1;
         var s:Sprite = new Sprite();
         s.graphics.lineStyle(1, 0xFFFFFF);
         s.graphics.beginFill(0x6A2BB5);
         s.graphics.drawCircle(0, 0, r);
         s.graphics.endFill();
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("宋体", Math.max(7, Math.round(box * (name.length > 1 ? 0.36 : 0.55))), 0xFFFFFF, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = name;
         t.x = -t.width / 2;
         t.y = -t.height / 2;
         s.addChild(t);
         into.addChild(s);
      }
   }
}
