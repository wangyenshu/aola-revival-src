package mmo.scene.yabi
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RLog;

   /**
    * REBUILT 亚比研究中心 (room "yabistudy") on the oldest surviving art of it,
    * scene/yabistudycopy (the newbie quest's copy, saved April 2014). The
    * January 2013 scene is lost and the live file is a 2025 redrawing. The
    * copy's own buttons are wired as the 2012 map names the centre's
    * functions. The 天赋改造机 (btnPetMix, a name kept from the 亚比融合 machine
    * it replaced): the January 2013 天赋改造 panel (PetGenius, pet/petgenius)
    * is lost, and the machine opens the 天赋启迪 of 17 January 2013
    * (activityres/activity130117/geniusedification), the era's other panel that
    * raises a 亚比's 天赋, whose own hint sends players to this machine. The pad
    * of the two 亚比 (btndetect) is the 亚比训练 (PetTraining, not rebuilt: it
    * says so). 亚比融合 (PetMixService) is 贝鲁特's (engine ScenePatches.MENUS),
    * the art having no machine of its own for it. The 亚比蛋 shop (btnbuyegg:
    * the 收费亚比蛋商品册). The ways out are
    * RECONSTRUCTED on the copy's signs: 升级基地 to the 亚比训练室, 进阶研究室 to
    * the 科学院, 奥拉广场 to 奥拉广场, and to 蓝宝石要塞 (where the later scene
    * led). 贝鲁特 and the other NPCs come from the NPC service as before.
    */
   public class YabistudyRevived extends SceneBase
   {
      public var obstruction:MovieClip;
      public var foreground:MovieClip;
      public var overlap:MovieClip;
      public var background:MovieClip;
      public var topground:MovieClip;

      /** [tip, scene, location key, x, y, width, height]. */
      private static const WAYS:Array = [
         ["亚比训练室", "yabitrain", "fromyabistudy", 340, 30, 150, 100],
         ["科学院", "science", "fromyabistudy", 760, 50, 180, 100],
         ["奥拉广场", "starland", "default", 760, 390, 200, 120],
         ["蓝宝石要塞", "bluesquare", "fromyabistudy", 0, 400, 160, 110]
      ];

      public function YabistudyRevived()
      {
         super(488, 244);
         addInitLocation("fromscience", new Point(700, 200));
         addInitLocation("fromyabitrain", new Point(430, 170));
         addInitLocation("hellotoyabi", new Point(488, 244));
         addInitLocation("fromjiujistudy", new Point(488, 300));
         addInitLocation("frombluesquare", new Point(300, 420));
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         for each (var w:Array in WAYS)
         {
            var s:Sprite = new Sprite();
            s.graphics.beginFill(0xFFFFFF, 1);
            s.graphics.drawRect(0, 0, w[5], w[6]);
            s.graphics.endFill();
            s.x = w[3];
            s.y = w[4];
            s.name = "way_" + w[1];
            (background || this).addChild(s);
            addEntrances(s, w[1], w[2]);
            TipsManager.getInstance().addTips(s, w[0]);
         }
         button("btnPetMix", "天赋改造机", showGenius);
         button("btndetect", "亚比训练", function():void { RLog.stub("PetTraining.showPanel"); });
         var egg:InteractiveObject = find(this, "btnbuyegg") as InteractiveObject;
         if (egg != null)
         {
            TipsManager.getInstance().addTips(egg, "亚比蛋");
            egg.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               e.stopImmediatePropagation();
               ServiceContainer.instance.tryGetService("SellBookService", function(svc:*, o:Object = null):void
               {
                  try { svc.showPage("catalog201006"); } catch (err:Error) { RLog.error("yabistudy egg book", err); }
               });
            });
         }
      }

      private function button(name:String, tip:String, f:Function):void
      {
         var b:InteractiveObject = find(this, name) as InteractiveObject;
         if (b == null) return;
         TipsManager.getInstance().addTips(b, tip);
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            try { f(); } catch (err:Error) { RLog.error("yabistudy " + name, err); }
         });
      }

      private static var energyRelay:Boolean;

      /**
       * 天赋启迪 (ActGeniusMainPanel). Its 启迪能量 comes from whoever answers its
       * GeniusEnergyCommand_Listen with GeniusEnergyCommand_Send (that code is lost): here,
       * the server's figure, asked with revival_genius_energy and sent with every
       * 天赋启迪 reply.
       */
      private static function showGenius():void
      {
         if (!energyRelay)
         {
            energyRelay = true;
            var relay:Function = function(e:SocketClientEvent):void
            {
               if (e.params != null && e.params.energy != null)
                  CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("GeniusEnergyCommand_Send", int(e.params.energy)));
            };
            for each (var cmd:String in ["revival_genius_energy", "0118genius_panel", "0118genius_power"])
               SocketClient.instance.addEventListener(cmd, relay);
            CommonEventDispatcher.instance.addEventListener("GeniusEnergyCommand_Listen", function(e:CommonEvent):void
            {
               SocketClient.instance.sendXtMessage("HolidayExtension", "revival_genius_energy", {});
            });
         }
         Panel_Helper.loadResAndShow("activityres/activity130117/geniusedification/geniusedificationpanel",
            "mmo.activity130117.geniusedification.ActGeniusMainPanel");
      }

      private static function find(d:DisplayObject, name:String):DisplayObject
      {
         if (d == null) return null;
         if (d.name == name) return d;
         var c:flash.display.DisplayObjectContainer = d as flash.display.DisplayObjectContainer;
         for (var i:int = 0; c != null && i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i), name);
            if (f != null) return f;
         }
         return null;
      }
   }
}
