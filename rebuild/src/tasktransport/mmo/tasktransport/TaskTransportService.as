package mmo.tasktransport
{
   import flash.display.GradientType;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.task.ITaskTransportService;
   import mmo.loader.layer.LayerManager;
   import mmo.config.ConfigReader;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT task/tasktransportpanel (ServiceConfig "TaskTransportPanelService",
    * ITaskTransportService). The 2013 module is lost: the task scripts open it
    * when a step sends the player elsewhere ("现在让我们立刻前往巨人山脚吧！") and
    * it takes them there. Drawn: the words, 立即前往 and 稍后再去.
    */
   public class TaskTransportService extends EventDispatcher implements ITaskTransportService
   {
      private var panel:Sprite;

      public function TaskTransportService()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function showTransportPanel(scene:String = "maintown2", text:String = null, extInfo:Object = null):*
      {
         close();
         var desc:String = "";
         try { desc = ConfigReader.instance.getSceneDescription(scene) || ""; } catch (e:Error) {}
         if (text == null || text == "") text = "现在就前往" + (desc || "那里") + "吗？";
         panel = new Sprite();
         panel.name = "taskTransportPanel";
         var g:Graphics = panel.graphics;
         g.beginFill(0x000000, 0.25);
         g.drawRect(0, 0, 960, 560);
         g.endFill();
         var m:Matrix = new Matrix();
         m.createGradientBox(420, 190, Math.PI / 2, 270, 170);
         g.lineStyle(3, 0x2E7DBE);
         g.beginGradientFill(GradientType.LINEAR, [0xF2FBFF, 0xC4E5F8], [1, 1], [0, 255], m);
         g.drawRoundRect(270, 170, 420, 190, 26, 26);
         g.endFill();
         panel.filters = [new DropShadowFilter(4, 90, 0x000000, 0.4, 10, 10)];
         var title:TextField = label("任务传送", 20, 0xFFF27A, 0x1A4E9C);
         title.x = 480 - title.width / 2;
         title.y = 180;
         panel.addChild(title);
         var words:TextField = new TextField();
         words.defaultTextFormat = new TextFormat("SimSun", 14, 0x1E4F80);
         words.multiline = words.wordWrap = true;
         words.width = 360;
         words.autoSize = TextFieldAutoSize.CENTER;
         words.selectable = false;
         words.htmlText = text;
         words.x = 300;
         words.y = 222;
         panel.addChild(words);
         panel.addChild(button("立即前往", 330, 300, function():void
         {
            close();
            SceneManager.getInstance().loadScene(scene, "default", false, false, "ld", extInfo);
         }));
         panel.addChild(button("稍后再去", 500, 300, close));
         panel.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         LayerManager.getBaseTop().addChild(panel);
         return panel;
      }

      private function close():void
      {
         if (panel != null && panel.parent) panel.parent.removeChild(panel);
         panel = null;
      }

      private static function button(text:String, x:Number, y:Number, fn:Function):Sprite
      {
         var b:Sprite = new Sprite();
         b.buttonMode = true;
         b.mouseChildren = false;
         var m:Matrix = new Matrix();
         m.createGradientBox(130, 36, Math.PI / 2, 0, 0);
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginGradientFill(GradientType.LINEAR, [0xFFC24D, 0xEF7A10], [1, 1], [0, 255], m);
         b.graphics.drawRoundRect(0, 0, 130, 36, 18, 18);
         b.graphics.endFill();
         var t:TextField = label(text, 15, 0xFFFFFF, 0x9A3A00);
         t.x = 65 - t.width / 2;
         t.y = 18 - t.height / 2;
         b.addChild(t);
         b.x = x;
         b.y = y;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            fn();
         });
         return b;
      }

      private static function label(text:String, size:int, color:uint, edge:uint):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("黑体", size, color, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = text;
         t.filters = [new GlowFilter(edge, 1, 3, 3, 10)];
         return t;
      }
   }
}
