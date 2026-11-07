package mmo.revival
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;

   /**
    * REVIVAL. One frame of a MovieClip class with its children built, for panels that take an
    * original timeline apart (the 2012 tutorials' copies of lost panels). Ruffle builds the
    * children of a frame gone to only once the clip is on the stage and a frame has passed:
    * the clip waits, hidden, in `host` until ready(clip) says its children are there.
    */
   public class RTimeline
   {
      public static function frame(cls:String, n:int, host:DisplayObjectContainer, ready:Function, done:Function):void
      {
         if (!ApplicationDomain.currentDomain.hasDefinition(cls) || host == null)
         {
            done(null);
            return;
         }
         var C:Class = getDefinitionByName(cls) as Class;
         var mc:MovieClip = new C() as MovieClip;
         mc.visible = false;
         mc.mouseEnabled = mc.mouseChildren = false;
         host.addChild(mc);
         mc.gotoAndStop(n);
         var tries:int = 0;
         var finish:Function = function(ok:Boolean):void
         {
            mc.removeEventListener(Event.ENTER_FRAME, check);
            if (mc.parent != null) mc.parent.removeChild(mc);
            mc.visible = true;
            mc.mouseEnabled = mc.mouseChildren = true;
            try { done(ok ? mc : null); }
            catch (e:Error) { RLog.error("timeline " + cls + " " + n, e); }
         };
         var check:Function = function(e:Event = null):void
         {
            var ok:Boolean = false;
            try { ok = mc.currentFrame == n && ready(mc); } catch (err:Error) {}
            if (ok) finish(true);
            else if (++tries > 40) { RLog.log("timeline " + cls + " " + n + ": not built"); finish(false); }
            else if (mc.currentFrame != n) mc.gotoAndStop(n);
         };
         mc.addEventListener(Event.ENTER_FRAME, check);
         check();
      }
   }
}
