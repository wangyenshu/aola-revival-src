package mmo.scene.temple
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.common.AlignType;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.bubble.BubbleTypes;
   import mmo.common.utils.bubble.BubbleUtil;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.data.TaskStepType;
   import mmo.play.activity.framework.util.LinkUtil;
   import mmo.play.actthings.data.ActClientSender;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;

   /**
    * LATER scene/temple1 (崩坏的上古神殿): the 2019 copy's code on the 2013
    * engine, on its own art. Touch the six pillars in turn, the 黑洞 film
    * plays, and the player is taken to 日月之境 (temple2; task 806's step
    * done first). The later code left the pillars' last clip looping: once
    * the scene was gone its frame script went on starting the film over
    * 日月之境 and every scene after it. Here the film plays once, the clips
    * stop when the scene goes, and if the task's update does not come back
    * the player is taken on after three seconds anyway.
    */
   public class Temple1Revived extends SceneBase
   {
      public var background:MovieClip;
      public var foreground:MovieClip;
      public var obstruction:MovieClip;
      public var overlap:MovieClip;
      public var topground:MovieClip;

      private static const POS:Array = [new Point(112, 347), new Point(593, 83), new Point(185, 123), new Point(757, 120), new Point(357, 98), new Point(850, 244)];
      private static const TYPES:Array = [BubbleTypes.RIGHT_BOTTOM, BubbleTypes.LEFT_TOP, BubbleTypes.LEFT_TOP, BubbleTypes.LEFT_TOP, BubbleTypes.LEFT_TOP, BubbleTypes.LEFT_TOP];

      private var num:int = 1;
      private var time:MovieClip;
      private var played:Boolean;
      private var going:Boolean;
      private var fallback:Timer;

      public function Temple1Revived()
      {
         super(470, 280);
         addInitLocation("fromtemple3", new Point(800, 250));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         for (var i:int = 1; i <= 6; i++)
         {
            var p:MovieClip = pillar(i);
            if (p == null) continue;
            p.addEventListener(MouseEvent.CLICK, onClick);
            p.buttonMode = true;
         }
         refreshBubble();
         var light:MovieClip = background.getChildByName("lightmc") as MovieClip;
         if (light != null)
         {
            TipsManager.getInstance().addTips(light, "洪荒战场");
            light.buttonMode = true;
            light.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { SceneManager.getInstance().loadScene("chaosbattle"); });
         }
      }

      private function pillar(i:int):MovieClip
      {
         var six:MovieClip = background.getChildByName("sixpillar") as MovieClip;
         return six ? six.getChildByName("pillar" + i) as MovieClip : null;
      }

      private function refreshBubble():void
      {
         for (var i:int = 1; i <= 6; i++)
         {
            var p:MovieClip = pillar(i);
            if (p == null) continue;
            if (i == num) BubbleUtil.instance.addBubble(p, ["点这里试试"], POS[i - 1].x, POS[i - 1].y, 2, 3, 0, TYPES[i - 1]);
            else BubbleUtil.instance.removeBubble(p);
         }
      }

      private function onClick(e:MouseEvent):void
      {
         var p:MovieClip = e.currentTarget as MovieClip;
         if (int(String(p.name).charAt(6)) == num)
         {
            p.gotoAndPlay(2);
            num++;
            refreshBubble();
            p.removeEventListener(MouseEvent.CLICK, onClick);
         }
         if (num == 7)
         {
            var six:MovieClip = background.getChildByName("sixpillar") as MovieClip;
            six.gotoAndPlay(2);
            var two:MovieClip = six.getChildByName("sixpillar2") as MovieClip;
            if (two != null) two.addFrameScript(two.totalFrames - 1, function():void
            {
               two.stop();
               two.addFrameScript(two.totalFrames - 1, null);
               movieEnd();
            });
            else movieEnd();
         }
      }

      private function movieEnd():void
      {
         if (played) return;
         played = true;
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("SWD_LittleTaskPanel", 3));
         var cls:Class = null;
         try { cls = getDefinitionByName("mmo.scene.temple.Time") as Class; } catch (e:Error) {}
         if (cls == null) { timeEnd(); return; }
         time = new cls() as MovieClip;
         time.gotoAndStop(1);
         time.addFrameScript(time.totalFrames - 1, function():void
         {
            time.addFrameScript(time.totalFrames - 1, null);
            timeEnd();
         });
         ModalDialogManager.getInstance().addModalDialog(time, AlignType.NONE, PanelEffect.NONE, true, 0, 0);
         time.gotoAndPlay(1);
      }

      private function timeEnd():void
      {
         if (time != null)
         {
            try { ModalDialogManager.getInstance().removeModalDialog(time); } catch (e:Error) {}
            time.stop();
            if (time.parent) time.parent.removeChild(time);
         }
         var ts:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         if (ts != null && ts.isUserTaskDoing(806))
         {
            TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_ADD, afterUpdate);
            ActClientSender.sendMessage("TaskExtension", "10-2", {ti: 806, ty: TaskStepType.CLIENT}, null);
            fallback = new Timer(3000, 1);
            fallback.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void { goOn(); });
            fallback.start();
         }
         else goOn();
      }

      private function afterUpdate(e:Event):void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_USER_TASK_ADD, afterUpdate);
         goOn();
      }

      private function goOn():void
      {
         if (going) return;
         going = true;
         if (fallback != null) fallback.stop();
         LinkUtil.gotoScene("temple2", "");
      }

      override protected function onLeaveRoom():void
      {
         super.onLeaveRoom();
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_USER_TASK_ADD, afterUpdate);
         if (fallback != null) fallback.stop();
         try
         {
            var six:MovieClip = background.getChildByName("sixpillar") as MovieClip;
            if (six != null)
            {
               six.stop();
               var two:MovieClip = six.getChildByName("sixpillar2") as MovieClip;
               if (two != null) { two.addFrameScript(two.totalFrames - 1, null); two.stop(); }
            }
            if (time != null)
            {
               time.addFrameScript(time.totalFrames - 1, null);
               time.stop();
               if (time.parent) time.parent.removeChild(time);
            }
         }
         catch (err:Error) { RLog.error("temple1 leave", err); }
      }
   }
}
