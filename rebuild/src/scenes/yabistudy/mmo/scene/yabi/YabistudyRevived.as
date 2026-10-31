package mmo.scene.yabi
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.scene.SceneBase;
   import mmo.revival.RLog;

   /**
    * REBUILT 亚比研究中心 (room "yabistudy") on the oldest surviving art of it,
    * scene/yabistudycopy (the newbie quest's copy, saved April 2014). The
    * January 2013 scene is lost and the live file is a 2025 redrawing. The
    * copy's own buttons are wired as the 2012 map names the centre's
    * functions: 亚比融合 (btnPetMix: PetMix), 天赋改造 (btndetect: PetGenius),
    * the 亚比蛋 shop (btnbuyegg: the 收费亚比蛋商品册). The ways out are
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
         panel("btnPetMix", "亚比融合", "PetMix");
         panel("btndetect", "亚比天赋改造", "PetGenius");
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

      private function panel(name:String, tip:String, service:String):void
      {
         var b:InteractiveObject = find(this, name) as InteractiveObject;
         if (b == null) return;
         TipsManager.getInstance().addTips(b, tip);
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            ServiceContainer.instance.tryGetService(service, function(svc:*, o:Object = null):void
            {
               try { svc.showPanel(); } catch (err:Error) { RLog.error("yabistudy " + service, err); }
            });
         });
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
