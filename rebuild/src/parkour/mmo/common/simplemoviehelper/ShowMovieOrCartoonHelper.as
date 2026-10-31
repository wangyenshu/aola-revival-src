package mmo.common.simplemoviehelper
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.utils.setTimeout;
   import mmo.common.AlignType;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;

   /**
    * REVIVAL (aola-revival). The later common library's ShowMovieOrCartoonHelper, as far as
    * 酷跑星世界 uses it (its first-visit movie, ParkourMainPanel): showMovieOrCartoon(true, url,
    * cls, callback, key) plays the movie `cls` of `url` once per player (key kept in LocalStore,
    * as the later helper), as a modal dialog until its last frame or its close button, then
    * calls back; with the key already set it calls back at once. Loaded with the 2013
    * SimpleCustomLoader.loadSingleResource (the later one took a child domain; the movie's
    * class is its own). Cartoons (movie false) are not used by the game and just call back.
    */
   public class ShowMovieOrCartoonHelper
   {
      public static function showMovieOrCartoon(movie:Boolean, url:String, cls:String, callback:Function = null, key:String = "", grayBackground:Boolean = true, hideAllDialog:Boolean = false):void
      {
         if (key.length > 0)
         {
            if (LocalStore.getValue(key, UserInfo.userName))
            {
               apply(callback);
               return;
            }
            LocalStore.setValue(key, true, UserInfo.userName);
         }
         if (!movie)
         {
            apply(callback);
            return;
         }
         var done:Boolean = false;
         var arrived:Boolean = false;
         SimpleCustomLoader.loadSingleResource(url, cls, LoadingSpriteType.NONE, "加载中，请稍候……", function(content:MovieClip, ... rest):void
         {
            arrived = true;
            var finish:Function = function(... r):void
            {
               if (done) return;
               done = true;
               content.removeEventListener(MouseEvent.CLICK, onClick);
               content.stop();
               ModalDialogManager.getInstance().removeModalDialog(content);
               apply(callback);
            };
            var onClick:Function = function(e:MouseEvent):void
            {
               var name:String = String(e.target.name).split("_")[0];
               if (name == "btnNext" || name == "btnnext") content.play();
               else if (name == "btnClose" || name == "btnclose") finish();
            };
            content.gotoAndStop(1);
            content.addEventListener(MouseEvent.CLICK, onClick);
            content.addFrameScript(content.totalFrames - 1, finish);
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(content, AlignType.NONE, 0, grayBackground);
            content.gotoAndPlay(1);
         }, null, function():void
         {
            // Called on success (just before the content), on a cancel and on a load error:
            // without the movie the game goes on.
            setTimeout(function():void
            {
               if (!arrived && !done)
               {
                  done = true;
                  apply(callback);
               }
            }, 0);
         });
      }

      private static function apply(callback:Function):void
      {
         if (callback != null) callback.apply();
      }
   }
}
