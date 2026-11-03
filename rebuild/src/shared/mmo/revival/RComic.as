package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Dictionary;
   import flash.utils.getDefinitionByName;
   import mmo.common.ProgressFullSprite;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;

   /**
    * REBUILT helper (the later games' ShowMovieOrCartoonHelper is not in the
    * 2013 libraries): plays one of the original task films or comics
    * (taskres/…, a MovieClip class) over the game, on a dark ground, and
    * calls back when its last frame is reached or 跳过 is pressed.
    */
   public class RComic
   {
      public static function play(url:String, cls:String, done:Function = null, skippable:Boolean = true):void
      {
         ProgressFullSprite.show();
         var finished:Boolean = false;
         var finish:Function = function():void
         {
            if (finished) return;
            finished = true;
            if (done != null) done();
         };
         ResScheduler.getResource(url, function(o:*):void
         {
            ProgressFullSprite.close();
            if (!ApplicationDomain.currentDomain.hasDefinition(cls))
            {
               RLog.log("comic: no " + cls + " in " + url);
               finish();
               return;
            }
            var mc:MovieClip;
            try { mc = new (getDefinitionByName(cls) as Class)() as MovieClip; } catch (e:Error) { RLog.error("comic " + cls, e); }
            if (mc == null) { finish(); return; }
            show(mc, finish, skippable);
         }, cls, function(e:* = null):void
         {
            ProgressFullSprite.close();
            RLog.log("comic: cannot load " + url);
            finish();
         });
      }

      private static function show(mc:MovieClip, finish:Function, skippable:Boolean):void
      {
         var top:DisplayObjectContainer = LayerManager.getBaseTop();
         var box:Sprite = new Sprite();
         box.name = "revivalComic";
         box.graphics.beginFill(0x000000, 0.82);
         box.graphics.drawRect(-200, -200, 1360, 960);
         box.graphics.endFill();
         box.addChild(mc);
         var closed:Boolean = false;
         var close:Function = function():void
         {
            if (closed) return;
            closed = true;
            box.removeEventListener(Event.ENTER_FRAME, onFrame);
            mc.stop();
            stopAll(mc);
            if (box.parent) box.parent.removeChild(box);
            finish();
         };
         // The films stop on their pages and wait for their own buttons: the arrow (next)
         // plays on to the next page, the close button (btnclose, end, ok …) ends the film.
         var wired:Dictionary = new Dictionary(true);
         var wire:Function = function(d:DisplayObject, depth:int):Boolean
         {
            var found:Boolean = false;
            var c:DisplayObjectContainer = d as DisplayObjectContainer;
            if (c == null) return false;
            for (var i:int = 0; i < c.numChildren; i++)
            {
               var k:DisplayObject = c.getChildAt(i);
               var kind:String = k is InteractiveObject ? BUTTONS[k.name] as String : null;
               if (kind != null)
               {
                  found = found || k.visible;
                  if (!wired[k])
                  {
                     wired[k] = true;
                     k.addEventListener(MouseEvent.CLICK, kind == "next" ? function(e:MouseEvent):void
                     {
                        e.stopPropagation();
                        if (mc.currentFrame >= mc.totalFrames) close();
                        else mc.play();
                     } : function(e:MouseEvent):void
                     {
                        e.stopPropagation();
                        close();
                     });
                  }
               }
               if (depth > 1 && wire(k, depth - 1)) found = true;
            }
            return found;
         };
         var onFrame:Function = function(e:Event):void { wire(mc, 3); };
         box.addEventListener(Event.ENTER_FRAME, onFrame);
         if (mc.totalFrames > 1)
         {
            // The last frame waits for its button when it has one.
            mc.addFrameScript(mc.totalFrames - 1, function():void { mc.stop(); if (!wire(mc, 3)) close(); });
         }
         if (skippable)
         {
            var skip:Sprite = new Sprite();
            skip.name = "btnSkip";
            skip.buttonMode = true;
            skip.mouseChildren = false;
            skip.graphics.lineStyle(2, 0xFFFFFF, 0.9);
            skip.graphics.beginFill(0x2D6FB8, 0.85);
            skip.graphics.drawRoundRect(0, 0, 70, 28, 14, 14);
            skip.graphics.endFill();
            var t:TextField = new TextField();
            t.defaultTextFormat = new TextFormat("黑体", 14, 0xFFFFFF, true);
            t.autoSize = TextFieldAutoSize.LEFT;
            t.selectable = false;
            t.text = mc.totalFrames > 1 ? "跳过 ▶" : "继续 ▶";
            t.filters = [new GlowFilter(0x0E3D73, 1, 3, 3, 8)];
            t.x = 35 - t.width / 2;
            t.y = 14 - t.height / 2;
            skip.addChild(t);
            skip.x = 870;
            skip.y = 516;
            skip.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); close(); });
            box.addChild(skip);
         }
         box.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         top.addChild(box);
         mc.gotoAndPlay(1);
      }

      /** The films' own buttons by name: next plays on, the others end the film. */
      private static const BUTTONS:Object = {
         next: "next", btnNext: "next", btnnext: "next", nextBtn: "next",
         end: "end", btnclose: "end", btnClose: "end", BTNCLOSE: "end", closeBtn: "end", cloBtn: "end",
         btn_close: "end", ok: "end", btnOk: "end"
      };

      private static function stopAll(d:DisplayObject):void
      {
         if (d is MovieClip) MovieClip(d).stop();
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null) return;
         for (var i:int = 0; i < c.numChildren; i++) stopAll(c.getChildAt(i));
      }
   }
}
