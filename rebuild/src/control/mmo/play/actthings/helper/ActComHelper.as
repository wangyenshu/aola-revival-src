package mmo.play.actthings.helper
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.utils.getQualifiedClassName;

   /**
    * REBUILT (later-engine helper, for scene files re-uploaded after 2013):
    * the display shortcuts those scenes call (children by name or dotted
    * path, frames, visibility, enabling). The activity-specific parts of
    * the later class (boss videos, tasks, anti-addiction) are not included.
    */
   public class ActComHelper
   {
      public static function tryGetPro(o:*, name:String, fallback:*):*
      {
         return o != null && o.hasOwnProperty(name) ? o[name] : fallback;
      }

      public static function getChildNode(c:DisplayObjectContainer, path:String):DisplayObject
      {
         var d:DisplayObject = c;
         for each (var part:String in path.split("."))
         {
            var box:DisplayObjectContainer = d as DisplayObjectContainer;
            d = box ? box.getChildByName(part) : null;
            if (d == null) break;
         }
         return d;
      }

      public static function getClassName(o:*):String
      {
         var n:String = getQualifiedClassName(o);
         return n.indexOf("::") >= 0 ? n.split("::")[1] : n;
      }

      public static function getMc(c:DisplayObjectContainer, name:String):MovieClip
      {
         return c ? c.getChildByName(name) as MovieClip : null;
      }

      public static function getBtn(c:DisplayObjectContainer, name:String):SimpleButton
      {
         return c ? c.getChildByName(name) as SimpleButton : null;
      }

      public static function setMcFrame(c:DisplayObjectContainer, path:String, frame:int):void
      {
         var mc:MovieClip = c ? getChildNode(c, path) as MovieClip : null;
         if (mc) mc.gotoAndStop(frame);
      }

      public static function setVisible(c:DisplayObjectContainer, path:String, v:Boolean):void
      {
         var d:DisplayObject = c ? getChildNode(c, path) : null;
         if (d) d.visible = v;
      }

      public static function safeCallback(c:DisplayObjectContainer, path:String, f:Function):void
      {
         var d:DisplayObject = c ? getChildNode(c, path) : null;
         if (d != null && f != null) f(d);
      }

      public static function setMcAble(d:DisplayObject, v:Boolean):void
      {
         if (d is MovieClip)
         {
            MovieClip(d).mouseChildren = MovieClip(d).mouseEnabled = MovieClip(d).enabled = v;
         }
         else if (d is SimpleButton)
         {
            SimpleButton(d).mouseEnabled = SimpleButton(d).enabled = v;
         }
      }

      public static function setMcEnable(c:MovieClip, path:String, v:Boolean):void
      {
         setMcAble(getChildNode(c, path), v);
      }

      public static function delayCall(f:Function):void
      {
         delayFrameCall(f, 1);
      }

      public static function delayFrameCall(f:Function, frames:int):void
      {
         var s:Sprite = new Sprite();
         var n:int = 0;
         s.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            if (++n < frames) return;
            s.removeEventListener(Event.ENTER_FRAME, arguments.callee);
            if (f != null) f();
         });
      }

      public static function isContainerNull(c:DisplayObjectContainer, where:String = ""):Boolean
      {
         return c == null;
      }

      public static function playOrHideMv(c:DisplayObjectContainer, path:String, play:Boolean, done:Function = null):void
      {
         var mc:MovieClip = c ? getChildNode(c, path) as MovieClip : null;
         if (mc == null)
         {
            if (done != null) done();
            return;
         }
         mc.visible = play;
         if (!play)
         {
            mc.gotoAndStop(1);
            if (done != null) done();
            return;
         }
         mc.gotoAndPlay(1);
         mc.addEventListener(Event.ENTER_FRAME, function(e:Event):void
         {
            if (mc.currentFrame < mc.totalFrames) return;
            mc.removeEventListener(Event.ENTER_FRAME, arguments.callee);
            mc.stop();
            if (done != null) done();
         });
      }

      public static function setSubMcsFrame(c:DisplayObjectContainer, prefix:String, count:int, start:int = 0, max:int = 30, on:int = 1, off:int = 2):void
      {
         var i:int = start;
         while (i < max)
         {
            var mc:MovieClip = c.getChildByName(prefix + i) as MovieClip;
            if (mc == null) break;
            mc.gotoAndStop(i - start < count ? on : off);
            i++;
         }
      }

      public static function removeTips(c:DisplayObjectContainer, name:String, a:Boolean = true, b:Boolean = true):void
      {
      }
   }
}
