package mmo.taskpanelnew
{
   import flash.display.DisplayObject;
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskPanelNewService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.data.TaskStarter;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneExtInfo;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT task/taskpanelnew (ServiceConfig "TaskPanelNewService"): the
    * 任务 button at the top right (its original art, mmo.taskicon.TaskIcon of
    * task/taskicon) and the panel of the tasks being done and of those that
    * can start. The 2013 panel is lost; this one shows each task's own
    * pictures from taskpanel/tp<id> (the task and its reward above, the
    * current step below; for the story quests the classes the later
    * TaskPanelResDefine names), framed in drawn glass, and takes the player
    * to where a task that can start begins (前往, with the scene's extInfo
    * taskIdFromTP as the 2013 task transport did).
    */
   public class TaskPanelNewService extends EventDispatcher implements ITaskPanelNewService
   {
      private var icon:Sprite;
      private var panel:Sprite;
      private var badge:Sprite;

      public function TaskPanelNewService()
      {
         super();
      }

      public function init():void
      {
         icon = new Sprite();
         icon.name = "taskIcon";
         icon.x = 912;
         icon.y = 8;
         icon.buttonMode = true;
         LayerManager.getBaseControl().addChild(icon);
         var cls:String = "mmo.taskicon.TaskIcon";
         ResScheduler.getResource("task/taskicon", function(o:*):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            icon.addChildAt(new (getDefinitionByName(cls) as Class)() as DisplayObject, 0);
         }, cls);
         icon.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            showBadge(false);
            showPanel();
         });
         icon.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_USER_TASK_ADD, function(e:TaskEvent):void { showBadge(true); });
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /** A small "!" on the button when a task or step has started. */
      private function showBadge(on:Boolean):void
      {
         if (badge != null && badge.parent) badge.parent.removeChild(badge);
         badge = null;
         if (!on || icon == null) return;
         badge = new Sprite();
         badge.mouseEnabled = badge.mouseChildren = false;
         badge.graphics.lineStyle(2, 0xFFFFFF);
         badge.graphics.beginFill(0xE8251E);
         badge.graphics.drawCircle(0, 0, 9);
         badge.graphics.endFill();
         var t:TextField = label("!", 13, 0xFFFFFF, 0x8A0000, "Arial");
         t.x = -t.width / 2;
         t.y = -t.height / 2;
         badge.addChild(t);
         badge.x = 46;
         badge.y = 6;
         icon.addChild(badge);
      }

      public function showPanel():void
      {
         if (panel != null && panel.parent) panel.parent.removeChild(panel);
         panel = new Sprite();
         panel.name = "taskPanel";
         var g:Graphics = panel.graphics;
         g.beginFill(0x000000, 0.35);
         g.drawRect(0, 0, 960, 560);
         g.endFill();
         var m:Matrix = new Matrix();
         m.createGradientBox(800, 480, Math.PI / 2, 80, 40);
         g.lineStyle(3, 0x2E7DBE);
         g.beginGradientFill(GradientType.LINEAR, [0xF2FBFF, 0xC4E5F8], [1, 1], [0, 255], m);
         g.drawRoundRect(80, 40, 800, 480, 30, 30);
         g.endFill();
         g.lineStyle(2, 0xFFFFFF, 0.9);
         g.drawRoundRect(86, 46, 788, 468, 24, 24);
         g.lineStyle();
         panel.filters = [new DropShadowFilter(4, 90, 0x000000, 0.4, 10, 10)];
         var title:TextField = label("星辉任务", 24, 0xFFF27A, 0x1A4E9C);
         title.x = 480 - title.width / 2;
         title.y = 50;
         panel.addChild(title);
         var close:Sprite = new Sprite();
         close.buttonMode = true;
         close.graphics.lineStyle(2, 0xFFFFFF);
         close.graphics.beginFill(0xE8601C);
         close.graphics.drawCircle(0, 0, 15);
         close.graphics.endFill();
         close.graphics.lineStyle(3, 0xFFFFFF);
         close.graphics.moveTo(-6, -6); close.graphics.lineTo(6, 6);
         close.graphics.moveTo(6, -6); close.graphics.lineTo(-6, 6);
         close.x = 866;
         close.y = 54;
         close.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (panel && panel.parent) panel.parent.removeChild(panel);
            panel = null;
         });
         panel.addChild(close);
         panel.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         panel.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         var ts:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         var doing:Array = ts ? ts.getDoingTaskIds() : [];
         var startable:Array = [];
         if (ts != null)
         {
            for (var k:String in ts.getTaskStarters())
            {
               var sid:int = int(k);
               if (ts.isTaskCanStart(sid) && sceneOf(sid) != "") startable.push(sid);
            }
            startable.sort(Array.NUMERIC);
         }
         var all:Array = doing.concat(startable).slice(0, 9);
         if (all.length == 0)
         {
            var none:TextField = label("现在没有进行中的任务。", 18, 0x1E4F80, 0xFFFFFFFF);
            none.x = 480 - none.width / 2;
            none.y = 260;
            panel.addChild(none);
         }
         else
         {
            var area:Sprite = new Sprite();
            panel.addChild(area);
            for (var i:int = 0; i < all.length; i++) panel.addChild(tab(ts, int(all[i]), i, area, doing.indexOf(all[i]) < 0));
            showTask(ts, int(all[0]), area, doing.indexOf(all[0]) < 0);
         }
         LayerManager.getBaseTop().addChild(panel);
      }

      private static function panelRes(id:int):Object
      {
         try
         {
            var r:Object = getDefinitionByName("mmo.taskdefines.TaskDefines").panelRes;
            return r ? r[id] : null;
         }
         catch (e:Error) {}
         return null;
      }

      /** Where a task begins: its panel's scene. */
      private static function sceneOf(id:int):String
      {
         var r:Object = panelRes(id);
         return r && r.sc ? String(r.sc) : "";
      }

      private function tab(ts:ITaskService, id:int, i:int, area:Sprite, canStart:Boolean = false):Sprite
      {
         var s:TaskStarter = ts.getTaskStarter(id);
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         var m:Matrix = new Matrix();
         m.createGradientBox(150, 34, Math.PI / 2, 0, 0);
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginGradientFill(GradientType.LINEAR, canStart ? [0x7FD3FF, 0x2E8BD8] : [0xFFC24D, 0xEF7A10], [1, 1], [0, 255], m);
         b.graphics.drawRoundRect(0, 0, 150, 34, 16, 16);
         b.graphics.endFill();
         var t:TextField = label((canStart ? "[可接] " : "") + (s ? s.taskName : String(id)), canStart ? 13 : 15, 0xFFFFFF, canStart ? 0x0E3D73 : 0x9A3A00);
         t.x = 75 - t.width / 2;
         t.y = 17 - t.height / 2;
         b.addChild(t);
         b.x = 104;
         b.y = 100 + i * 44;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            showTask(ts, id, area, canStart);
         });
         return b;
      }

      /** Task<id> (the task) above Task<step> (what to do now), from taskpanel/tp<id>. */
      private function showTask(ts:ITaskService, id:int, area:Sprite, canStart:Boolean = false):void
      {
         while (area.numChildren) area.removeChildAt(0);
         var res:Object = panelRes(id);
         var url:String = res && res.fn ? String(res.fn) : "taskpanel/tp" + id;
         var cls:String = res && res.cn ? String(res.cn) : "mmo.taskpanel.Task" + id;
         var stepId:int = canStart ? -1 : ts.getTaskDoingStep(id);
         var stepRes:Object = stepId > 0 ? panelRes(stepId) : null;
         var stepCls:String = stepRes && stepRes.cn ? String(stepRes.cn) : "mmo.taskpanel.Task" + stepId;
         ResScheduler.getResource(url, function(o:*):void
         {
            put(area, cls, 280, 96, 560, 210);
            if (stepId > 0) put(area, stepCls, 290, 300, 560, 210);
         }, cls);
         if (canStart) area.addChild(goButton(id));
      }

      /** 前往: to the scene the task begins in, telling it which task brought the player (taskIdFromTP). */
      private function goButton(id:int):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         var m:Matrix = new Matrix();
         m.createGradientBox(160, 40, Math.PI / 2, 0, 0);
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginGradientFill(GradientType.LINEAR, [0xFFC24D, 0xEF7A10], [1, 1], [0, 255], m);
         b.graphics.drawRoundRect(0, 0, 160, 40, 20, 20);
         b.graphics.endFill();
         var t:TextField = label("前往", 18, 0xFFFFFF, 0x9A3A00);
         t.x = 80 - t.width / 2;
         t.y = 20 - t.height / 2;
         b.addChild(t);
         b.x = 480;
         b.y = 440;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (panel && panel.parent) panel.parent.removeChild(panel);
            panel = null;
            var ext:SceneExtInfo = new SceneExtInfo();
            ext.taskIdFromTP = id;
            SceneManager.getInstance().loadScene(sceneOf(id), "default", true, false, "ld", ext);
         });
         return b;
      }

      private static function put(into:Sprite, cls:String, x:Number, y:Number, w:Number, h:Number):void
      {
         if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
         var d:DisplayObject = new (getDefinitionByName(cls) as Class)() as DisplayObject;
         var b:Rectangle = d.getBounds(d);
         var k:Number = Math.min(1, w / Math.max(1, b.width), h / Math.max(1, b.height));
         d.scaleX = d.scaleY = k;
         d.x = x - b.left * k;
         d.y = y - b.top * k;
         into.addChild(d);
      }

      private static function label(text:String, size:int, color:uint, edge:uint, font:String = "黑体"):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat(font, size, color, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = text;
         if (edge != 0xFFFFFFFF) t.filters = [new GlowFilter(edge, 1, 3, 3, 10)];
         return t;
      }
   }
}
