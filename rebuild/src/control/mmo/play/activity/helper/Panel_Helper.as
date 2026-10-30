package mmo.play.activity.helper
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.revival.RLog;

   /** REBUILT (later-engine helper): open an activity panel from its file, and small display shortcuts. */
   public class Panel_Helper
   {
      public static function loadResAndShow(file:String, cls:String, params:Object = null, domain:* = null, done:Function = null, x:int = -1):void
      {
         SimpleCustomLoader.loadSingleResource(file, cls, LoadingSpriteType.DIALOG, "请稍等……", function(p:*):void
         {
            try
            {
               if (params != null) for (var k:String in params) if (p.hasOwnProperty(k)) p[k] = params[k];
               if (p.hasOwnProperty("showPanel")) p.showPanel();
               else if (p.hasOwnProperty("show")) p.show();
            }
            catch (e:Error)
            {
               RLog.error("Panel_Helper " + file, e);
            }
            if (done != null) done(p);
         });
      }

      public static function setVisible(c:DisplayObjectContainer, name:String, v:Boolean):void
      {
         var d:DisplayObject = c ? c.getChildByName(name) : null;
         if (d) d.visible = v;
      }

      public static function setViewStack(c:DisplayObjectContainer, name:String, frame:int):void
      {
         var mc:MovieClip = c ? c.getChildByName(name) as MovieClip : null;
         if (mc) mc.gotoAndStop(frame);
      }

      public static function setTextValue(c:DisplayObjectContainer, name:String, text:String):void
      {
         var t:TextField = c ? c.getChildByName(name) as TextField : null;
         if (t) t.text = text;
      }

      public static function setText(t:TextField, text:String):void
      {
         if (t) t.text = text;
      }

      public static function setHtmlText(t:TextField, text:String):void
      {
         if (t) t.htmlText = text;
      }

      public static function getNameIndex(name:String, prefix:String = ""):int
      {
         return int(name.replace(prefix, "").replace(/\D/g, ""));
      }
   }
}
