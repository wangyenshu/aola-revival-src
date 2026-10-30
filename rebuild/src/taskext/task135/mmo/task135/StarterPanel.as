package mmo.task135
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT: choosing the first 亚比 (step 137). In the screenshot of the
    * December 2011 walkthrough the three 初始亚比 stand on a round platform
    * in the 指挥中心: 滴滴, 吉拉 and 兔小子. Drawn here as that platform with
    * the 亚比's own big icons (peticon<race>_L); a click picks one and
    * 就决定是它了！ confirms.
    */
   public class StarterPanel extends Sprite
   {
      private static const PETS:Array = [[7, "滴滴", "水系", 0x3A9BE6], [4, "吉拉", "火系", 0xF0642A], [1, "兔小子", "草系", 0x4BB543]];
      private var onPick:Function;
      private var chosen:int = -1;
      private var pads:Array = [];
      private var ok:Sprite;

      public function StarterPanel(onPick:Function)
      {
         super();
         this.onPick = onPick;
         var g:Graphics = graphics;
         g.beginFill(0x000000, 0.55);
         g.drawRect(-100, -100, 1160, 760);
         g.endFill();
         // The round platform.
         var m:Matrix = new Matrix();
         m.createGradientBox(620, 190, Math.PI / 2, 170, 250);
         g.lineStyle(3, 0x8FDFFF);
         g.beginGradientFill(GradientType.LINEAR, [0xE9F8FF, 0x9ED4F0, 0x4C93C9], [1, 1, 1], [0, 140, 255], m);
         g.drawEllipse(170, 250, 620, 190);
         g.endFill();
         g.lineStyle(2, 0xFFFFFF, 0.8);
         g.drawEllipse(190, 262, 580, 160);
         g.lineStyle();
         g.beginFill(0x2C6FA8);
         g.drawRect(178, 345, 604, 26);
         g.endFill();
         var title:TextField = label("选一只亚比做你的伙伴吧！", 26, 0xFFF27A, 0x1A4E9C);
         title.x = 480 - title.width / 2;
         title.y = 70;
         addChild(title);
         for (var i:int = 0; i < PETS.length; i++) addChild(pad(i, PETS[i]));
         ok = new Sprite();
         ok.buttonMode = true;
         ok.mouseChildren = false;
         var og:Graphics = ok.graphics;
         m = new Matrix();
         m.createGradientBox(220, 46, Math.PI / 2, 0, 0);
         og.lineStyle(2, 0xFFFFFF);
         og.beginGradientFill(GradientType.LINEAR, [0xFFC24D, 0xEF7A10], [1, 1], [0, 255], m);
         og.drawRoundRect(0, 0, 220, 46, 24, 24);
         og.endFill();
         var ot:TextField = label("就决定是它了！", 20, 0xFFFFFF, 0x9A3A00);
         ot.x = 110 - ot.width / 2;
         ot.y = 23 - ot.height / 2;
         ok.addChild(ot);
         ok.x = 370;
         ok.y = 470;
         ok.visible = false;
         var self:StarterPanel = this;
         ok.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (chosen < 0) return;
            if (self.parent) self.parent.removeChild(self);
            onPick(int(PETS[chosen][0]));
         });
         addChild(ok);
         addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
      }

      public function show():void
      {
         LayerManager.getBaseTop().addChild(this);
      }

      private function pad(i:int, p:Array):Sprite
      {
         var s:Sprite = new Sprite();
         s.x = 300 + i * 180;
         s.y = 300;
         s.buttonMode = true;
         var ring:Sprite = new Sprite();
         s.addChild(ring);
         var pic:Sprite = new Sprite();
         pic.y = 6;
         s.addChild(pic);
         loadIcon(int(p[0]), pic);
         var name:TextField = label(p[1], 20, 0xFFFFFF, p[3]);
         name.x = -name.width / 2;
         name.y = 30;
         s.addChild(name);
         var kind:TextField = label(p[2], 14, 0xFFFFFF, 0x214C7A);
         kind.x = -kind.width / 2;
         kind.y = 58;
         s.addChild(kind);
         var draw:Function = function(on:Boolean):void
         {
            var g:Graphics = ring.graphics;
            g.clear();
            var mm:Matrix = new Matrix();
            mm.createGradientBox(120, 44, Math.PI / 2, -60, -22);
            g.lineStyle(3, on ? 0xFFD54A : 0xFFFFFF);
            g.beginGradientFill(GradientType.LINEAR, on ? [0xFFF6C9, 0xFFB43C] : [0xF6FCFF, 0xA6D6F2], [1, 1], [0, 255], mm);
            g.drawEllipse(-60, -22, 120, 44);
            g.endFill();
            ring.filters = on ? [new GlowFilter(0xFFE36B, 0.9, 16, 16, 2)] : [];
         };
         draw(false);
         pads.push(draw);
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            chosen = i;
            for (var k:int = 0; k < pads.length; k++) pads[k](k == i);
            ok.visible = true;
         });
         return s;
      }

      private static function loadIcon(race:int, into:Sprite):void
      {
         var cls:String = "mmo.pet.peticon" + race + "_L";
         var put:Function = function(... a):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var d:DisplayObject = new (getDefinitionByName(cls) as Class)() as DisplayObject;
            var b:Rectangle = d.getBounds(d);
            var k:Number = Math.min(1.4, 130 / Math.max(1, b.width), 130 / Math.max(1, b.height));
            d.scaleX = d.scaleY = k;
            d.x = -(b.left + b.width / 2) * k;
            d.y = -b.bottom * k;
            d.filters = [new DropShadowFilter(4, 90, 0x000000, 0.4, 6, 6)];
            into.addChild(d);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("peticon/peticon" + race, put, cls, function(e:* = null):void {});
      }

      private static function label(text:String, size:int, color:uint, edge:uint):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("黑体", size, color, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = text;
         t.filters = [new GlowFilter(edge, 1, 4, 4, 10)];
         return t;
      }
   }
}
