package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
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
         var close:Function = function():void
         {
            mc.stop();
            stopAll(mc);
            if (box.parent) box.parent.removeChild(box);
            finish();
         };
         if (mc.totalFrames > 1)
         {
            mc.addFrameScript(mc.totalFrames - 1, function():void { mc.stop(); close(); });
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

      private static function stopAll(d:DisplayObject):void
      {
         if (d is MovieClip) MovieClip(d).stop();
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null) return;
         for (var i:int = 0; i < c.numChildren; i++) stopAll(c.getChildAt(i));
      }
   }
}
