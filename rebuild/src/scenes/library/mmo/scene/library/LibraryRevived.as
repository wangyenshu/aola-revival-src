package mmo.scene.library
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.loader.layer.LayerManager;

   /**
    * LATER scene/library (图书馆): the 2019 copy's art with its doors and
    * buttons answered on the 2013 engine (the January 2013 scene is lost).
    * Its 往期周刊 button (btnhistoryweekly, which the later code left
    * unused) opens the shelf of 奥拉周刊 back issues (LibraryShelf: every
    * issue game/ has, tools/weeklies.py) and the era books 亚比手册 and
    * 蓝宝石最新消息; 奥拉图书 opens the same shelf; 动画库 and 周年视频 open
    * the 百田大剧场's films (the page's theatre panel, web/theatre.js), the
    * later 动画库 book (book201110) being lost; 小南邮箱 is the feedback
    * service as before.
    */
   public class LibraryRevived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      public function LibraryRevived()
      {
         super(450, 350);
         addInitLocation("fromcrossroad", new Point(789, 432));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         var et1:InteractiveObject = foreground.getChildByName("et1") as InteractiveObject;
         if (et1 != null)
         {
            TipsManager.getInstance().addTips(et1, "十字大道");
            addEntrances(et1, "crossroad", "fromlibray");
         }
         button(background.getChildByName("btnhistoryweekly"), "往期周刊", LibraryShelf.show);
         button(foreground.getChildByName("btnyabibook"), "奥拉图书", LibraryShelf.show);
         button(background.getChildByName("btnmovie"), "动画库", function():void { page("showVideoPlayer"); });
         button(background.getChildByName("btnboard"), "周年视频", function():void { page("showAnniversaryVideo"); });
         button(background.getChildByName("btnmail"), "小南邮箱", feedback);
      }

      private static function button(d:DisplayObject, tip:String, f:Function):void
      {
         var io:InteractiveObject = d as InteractiveObject;
         if (io == null) return;
         if (io is MovieClip) MovieClip(io).buttonMode = true;
         try { TipsManager.getInstance().addTips(io, tip); } catch (e:Error) {}
         io.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            f();
         });
      }

      private static function page(fn:String):void
      {
         try { if (ExternalInterface.available) { ExternalInterface.call(fn); return; } }
         catch (e:Error) { RLog.error("library " + fn, e); }
         RNotice.show(LayerManager.getBaseTop(), "这个页面放不了视频。");
      }

      private static function feedback():void
      {
         ServiceContainer.instance.tryGetService("FeedbackService", function(svc:Object, o:Object):void
         {
            try { svc.showFeedBackList(); } catch (e:Error) { RLog.error("library mail", e); }
         });
      }
   }
}
