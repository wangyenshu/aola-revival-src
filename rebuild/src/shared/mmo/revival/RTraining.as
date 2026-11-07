package mmo.revival
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getQualifiedClassName;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.layer.LayerManager;

   /**
    * REVIVAL. 亚比训练 (the HELLO's, the 亚比仓库's 训练 and 开始训练): the 亚比 in training
    * first (pet/petbetraining), else the lessons (pet/pettraining). The 2010 panel of those in
    * training writes 剩余训练时间 in hours (its code: the seconds left / 3600) before the
    * word 分钟 of its picture, and its box holds two figures; the lessons last 一天 to 七天:
    * the time left is written here over both, in hours (小时).
    */
   public class RTraining
   {
      private static const PANEL:String = "mmo.pet.petbetraining::PetBeTrainingPanel";
      private static const BACK:uint = 0xE3FBFF;

      public static function open():void
      {
         SocketClient.instance.addEventListener(RobotClient.cmdGetTrain, onList);
         RobotClient.instance.getTrain();
      }

      private static function onList(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(RobotClient.cmdGetTrain, onList);
         var name:String = ((e.params.ps as Array) || []).length > 0 ? "PetBeTraining" : "PetTraining";
         ServiceContainer.instance.tryGetService(name, function(svc:IService, o:Object = null):void
         {
            try { IShowPanel(svc).showPanel(); } catch (err:Error) { RLog.error("training " + name, err); return; }
            if (name == "PetBeTraining") dress();
         });
      }

      private static function dress():void
      {
         var top:DisplayObjectContainer = LayerManager.getBaseTop();
         for (var i:int = 0; top != null && i < top.numChildren; i++)
         {
            var p:DisplayObjectContainer = top.getChildAt(i) as DisplayObjectContainer;
            if (p == null || getQualifiedClassName(p) != PANEL || p.getChildByName("trainLeft") != null) continue;
            var t0:TextField = p.getChildByName("t0") as TextField;
            if (t0 == null) continue;
            var box:Sprite = new Sprite();
            box.name = "trainLeft";
            box.mouseEnabled = box.mouseChildren = false;
            box.x = t0.x;
            box.y = t0.y;
            box.graphics.beginFill(BACK);
            box.graphics.drawRect(-2, -2, 78, 26);
            box.graphics.endFill();
            var num:TextField = field(18, 0xFF0000);
            var unit:TextField = field(15, 0x0066CC);
            unit.text = "小时";
            box.addChild(num);
            box.addChild(unit);
            p.addChild(box);
            t0.visible = false;
            var sync:Function = function(e:Event = null):void
            {
               if (num.text == t0.text && e != null) return;
               num.text = t0.text;
               unit.x = num.width + 2;
               unit.y = num.height - unit.height - 1;
            };
            box.addEventListener(Event.ENTER_FRAME, sync);
            sync();
         }
      }

      private static function field(size:int, color:uint):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("黑体", size, color, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         return t;
      }
   }
}
