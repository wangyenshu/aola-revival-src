package mmo.user.login
{
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL. The page's side of the start screens (web/start.js): aolaStartPage(op, args, id),
    * answered in revivalStart(id, result); and the pieces the screens are drawn with.
    */
   public class StartPage
   {
      private static const NO_PAGE:String = "这个页面不能这样做。";
      private static var calls:Object = {};
      private static var nextCall:int;
      /** The file being saved or read (kept while its dialog is open). */
      private static var file:FileReference;

      /** What the start screen fills in: {mode, server, serverName, pass}. */
      public static function saved():Object
      {
         try
         {
            var s:Object = ExternalInterface.available ? ExternalInterface.call("aolaStartPage", "saved") : null;
            if (s != null) return s;
         }
         catch (e:Error) { RLog.error("start saved", e); }
         return { mode: "inpage", server: "", serverName: "", pass: "" };
      }

      public static function ask(op:String, args:Object, then:Function):void
      {
         try
         {
            if (ExternalInterface.available)
            {
               ExternalInterface.addCallback("revivalStart", answer);
               var id:String = String(++nextCall);
               calls[id] = then;
               if (ExternalInterface.call("aolaStartPage", op, args, id) === true) return;
               delete calls[id];
            }
         }
         catch (e:Error) { RLog.error("start " + op, e); }
         then({ error: NO_PAGE });
      }

      private static function answer(id:String, r:Object):void
      {
         var f:Function = calls[id] as Function;
         delete calls[id];
         if (f != null) f(r || {});
      }

      /** Flash's save dialog for this text; said(message) when it is saved or not. */
      public static function save(text:String, name:String, said:Function):void
      {
         file = new FileReference();
         file.addEventListener(Event.COMPLETE, function(e:Event):void { said("已导出。"); });
         file.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { said("没有保存。"); });
         try { file.save(text, name); }
         catch (err:Error) { said("没有保存：" + err.message); }
      }

      /** Flash's open dialog: the chosen file's text to then; said(message) on a failure. */
      public static function read(then:Function, said:Function):void
      {
         var f:FileReference = file = new FileReference();
         f.addEventListener(Event.SELECT, function(e:Event):void { f.load(); });
         f.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            var b:ByteArray = f.data;
            b.position = 0;
            then(b.readUTFBytes(b.length));
         });
         f.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { said("读不了这个文件。"); });
         try { f.browse([new FileFilter("奥拉星存档 (*.json)", "*.json")]); }
         catch (err:Error) { said("打不开选文件的窗口：" + err.message); }
      }

      // ---------------------------------------------------------------- drawing

      /** The blue of the start screens, over the whole stage. */
      public static function backdrop():Shape
      {
         var s:Shape = new Shape();
         var m:Matrix = new Matrix();
         m.createGradientBox(1300, 1100, 0, 480 - 650, 196 - 550);
         s.graphics.beginGradientFill(GradientType.RADIAL, [0x3A9BE8, 0x0B3F86, 0x072A5E], [1, 1, 1], [0, 178, 255], m);
         s.graphics.drawRect(0, 0, 960, 560);
         s.graphics.endFill();
         return s;
      }

      /** A title in yellow with a blue edge (选择奥拉). */
      public static function title(text:String, size:int):TextField
      {
         var t:TextField = RUI.text(size, 0xFFF27A, true);
         t.text = text;
         t.filters = [new GlowFilter(0x1A4E9C, 1, 4, 4, 6), new DropShadowFilter(3, 90, 0x1A4E9C, 1, 0, 0, 4)];
         return t;
      }

      public static function centred(size:int, color:uint, bold:Boolean, w:int):TextField
      {
         var t:TextField = RUI.text(size, color, bold, w);
         var f:TextFormat = t.defaultTextFormat;
         f.align = TextFormatAlign.CENTER;
         t.defaultTextFormat = f;
         return t;
      }

      /** An underlined text button. */
      public static function link(label:String, f:Function, color:uint = 0x2A628F, name:String = null):Sprite
      {
         var s:Sprite = new Sprite();
         if (name) s.name = name;
         s.buttonMode = true;
         s.mouseChildren = false;
         var t:TextField = RUI.text(13, color, false);
         var fmt:TextFormat = t.defaultTextFormat;
         fmt.underline = true;
         t.defaultTextFormat = fmt;
         t.text = label;
         s.addChild(t);
         s.graphics.beginFill(0, 0);
         s.graphics.drawRect(-2, -2, t.width + 4, t.height + 4);
         s.graphics.endFill();
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); f(); });
         return s;
      }

      /** A tick box with its words (ticked(it): its state). */
      public static function tick(label:String, on:Boolean, name:String):Sprite
      {
         var s:Sprite = new Sprite();
         s.name = name;
         s.buttonMode = true;
         s.mouseChildren = false;
         var box:Shape = new Shape();
         s.addChild(box);
         var t:TextField = RUI.text(12, 0x12406F, false);
         t.text = label;
         t.x = 18;
         t.y = -2;
         s.addChild(t);
         var state:Object = { on: on };
         var draw:Function = function():void
         {
            box.graphics.clear();
            box.graphics.lineStyle(1.5, 0x5FA8E0);
            box.graphics.beginFill(0xFFFFFF);
            box.graphics.drawRoundRect(0, 0, 14, 14, 4, 4);
            box.graphics.endFill();
            if (state.on)
            {
               box.graphics.lineStyle(2.5, 0xF07812);
               box.graphics.moveTo(3, 7);
               box.graphics.lineTo(6, 11);
               box.graphics.lineTo(12, 3);
            }
         };
         draw();
         s.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            state.on = !state.on;
            draw();
         });
         s.graphics.beginFill(0, 0);
         s.graphics.drawRect(0, -2, 18 + t.width, 18);
         s.graphics.endFill();
         TICKS[s] = state;
         return s;
      }

      private static const TICKS:Dictionary = new Dictionary(true);

      public static function ticked(s:Sprite):Boolean
      {
         return TICKS[s] != null && TICKS[s].on;
      }
   }
}
