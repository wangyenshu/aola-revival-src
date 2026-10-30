package mmo.hellohelper.helloicon
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.hellohelper.IHelloIconService;
   import mmo.interfaces.task.ITaskService;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;

   /**
    * REBUILT hellohelper/helloiconservice (ServiceConfig "HelloIconService"):
    * the HELLO on the control bar. The January 2013 module (version 130110)
    * is lost; the copy archived under its URL was rebuilt in November 2013
    * and no longer calls its own HELLO code. This puts that code back to
    * work, as its structure shows it ran: when the first scene is ready, the
    * bar's "hello" place gives way to the HELLO button of
    * hellohelper/helloiconres (mmo.hellohelper.helloicon.Normal), which
    * first comes out of its stand (ComeOut, "主人，这里有好玩的活动哦！") and
    * then every 300 s plays one of its little films (TimeMovie_EXP / _PetDic
    * / _Zoo). Clicking it opens the newest 奥拉周刊 (WeeklyService), except
    * during the first newbie tasks (135, 140, 150).
    *
    * Not rebuilt: the weekly newbie gifts the HELLO handed out after task
    * 150 (hellohelper/newbiehelloiconres, which survives, opened
    * onlinegiftpanel/newbieweeklygiftpanel, which does not).
    */
   public class HelloIconService extends EventDispatcher implements IHelloIconService
   {
      private const resPath:String = "hellohelper/helloiconres";
      private const btnHelloStr:String = "mmo.hellohelper.helloicon.Normal";
      private const mcComeOutStr:String = "mmo.hellohelper.helloicon.ComeOut";
      private const mcHelloStrArr:Array = ["mmo.hellohelper.helloicon.TimeMovie_EXP", "mmo.hellohelper.helloicon.TimeMovie_PetDic", "mmo.hellohelper.helloicon.TimeMovie_Zoo"];
      private const actionTime:int = 300;

      private var con:DisplayObjectContainer;
      private var btnHello:SimpleButton;
      private var helloPoint:Point;
      private var helloMovie:MovieClip;
      private var movieTimer:Timer;

      public function HelloIconService()
      {
         super();
      }

      public function init():void
      {
         var sm:SceneManager = SceneManager.getInstance();
         if (sm.loadedSceneInfo != null && !sm.isLoading) initHello();
         else sm.addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInit);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      private function onSceneInit(e:SceneManagerEvent):void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.SCENE_INITED, onSceneInit);
         initHello();
      }

      private function initHello():void
      {
         con = LayerManager.getBaseControl().getChildByName("controlBar") as DisplayObjectContainer;
         if (con == null) return;
         var helloSp:DisplayObject = con.getChildByName("hello");
         if (helloSp == null) return;
         helloPoint = new Point(helloSp.x, helloSp.y);
         con.removeChild(helloSp);
         ResScheduler.getResource(resPath, function(btn:SimpleButton):void
         {
            btnHello = btn;
            btnHello.x = helloPoint.x;
            btnHello.y = helloPoint.y;
            btnHello.name = "btnHello";
            con.addChild(btnHello);
            btnHello.addEventListener(MouseEvent.CLICK, onClickSb);
            showHelloMovie(mcComeOutStr, null);
            initTimer();
         }, btnHelloStr);
      }

      private function initTimer():void
      {
         movieTimer = new Timer(1000 * actionTime, 0);
         movieTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { showRandomMovie(); });
         movieTimer.start();
      }

      private function showRandomMovie():void
      {
         if (helloMovie != null) return;
         showHelloMovie(mcHelloStrArr[int(Math.random() * mcHelloStrArr.length)], null);
      }

      private function showHelloMovie(clsName:String, callback:Function):void
      {
         if (!ApplicationDomain.currentDomain.hasDefinition(clsName) || con == null) return;
         var cls:Class = ApplicationDomain.currentDomain.getDefinition(clsName) as Class;
         var mc:MovieClip = new cls() as MovieClip;
         helloMovie = mc;
         mc.addFrameScript(mc.totalFrames - 1, function():void
         {
            btnHello.visible = true;
            mc.stop();
            if (mc.parent) mc.parent.removeChild(mc);
            helloMovie = null;
            if (callback != null) callback.apply();
         });
         mc.x = helloPoint.x;
         mc.y = helloPoint.y;
         mc.mouseEnabled = mc.mouseChildren = false;
         btnHello.visible = false;
         con.addChild(mc);
         mc.gotoAndPlay(1);
      }

      private function onClickSb(e:MouseEvent):void
      {
         SocketClient.instance.sendXtMessage("SundriesExtension", "70_8", {id: 164});
         try
         {
            var ts:ITaskService = ServiceContainer.getService("TaskService") as ITaskService;
            if (ts != null && (ts.isUserTaskDoing(135) || ts.isUserTaskDoing(140) || ts.isUserTaskDoing(150))) return;
         }
         catch (err:Error) {}
         ServiceContainer.instance.tryGetService("WeeklyService", function(svc:IService, o:Object):void
         {
            Object(svc).showLastestWeekly();
         });
      }
   }
}
