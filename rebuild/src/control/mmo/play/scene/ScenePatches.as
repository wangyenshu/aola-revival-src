package mmo.play.scene
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;

   /**
    * REVIVAL. Small fixes to scenes whose files are later copies, made when
    * the scene is shown (SceneManager, after SCENE_INITED).
    *
    * The lift of the shops (btnLadder, "点我前往其他楼层", showing 种植园,
    * 家具店 and 服装店): in the later copies of 家具店 (2017), 服装店 and
    * 种植园 (2018) nothing listens to it any more. A click shows the three
    * floors to go to.
    *
    * 体育馆's 斑比向前冲 (a later game, its button in the later scene).
    * 日月之境 and 木石之境: their way back to 崩坏的上古神殿.
    */
   public class ScenePatches
   {
      private static const FLOORS:Array = [["种植园", "plantpark", "default"], ["家具店", "furnitureshop", "fromplantpark"], ["服装店", "clothesshop", "default"]];

      private static var menu:Sprite;

      public static function apply(info:SceneInfo):void
      {
         closeMenu();
         if (info == null || info.scene == null) return;
         try
         {
            switch (String(info.sceneName))
            {
               case "furnitureshop":
               case "clothesshop":
               case "plantpark":
                  lift(info);
                  break;
               case "temple2":
               case "temple3":
                  // 日月之境 and 木石之境 (later copies) keep their first door (et1) hidden and
                  // without a target: in 2013 it led back to 崩坏的上古神殿.
                  door(info, "et1", "temple1", "from" + info.sceneName, "崩坏的上古神殿");
                  break;
               case "gymnasium":
                  // 斑比向前冲: the later scene asks the later GameTable's GAME_NINJA_RUSH (66),
                  // which the 2013 one lacks; the revival's GameManager knows its room.
                  takeOver(info, "btnNinjaRush", function():void { showGame(66); });
                  break;
            }
         }
         catch (e:Error) { RLog.error("scene patch " + info.sceneName, e); }
      }

      private static function find(d:DisplayObject, name:String, depth:int = 4):DisplayObject
      {
         if (d == null) return null;
         if (d.name == name) return d;
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c == null || depth <= 0) return null;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            var f:DisplayObject = find(c.getChildAt(i), name, depth - 1);
            if (f != null) return f;
         }
         return null;
      }

      private static function door(info:SceneInfo, name:String, to:String, key:String, tip:String):void
      {
         var scene:SceneBase = info.scene as SceneBase;
         var et:DisplayObject = find(info.scene, name, 3);
         if (scene == null || et == null) return;
         scene.revival::addEntranceFor(et, to, key);
         try { TipsManager.getInstance().addTips(et as InteractiveObject, tip); } catch (e:Error) {}
      }

      /** Answer a button before the scene's own listener does (and instead of it). */
      private static function takeOver(info:SceneInfo, name:String, f:Function):void
      {
         var btn:InteractiveObject = find(info.scene, name, 5) as InteractiveObject;
         if (btn == null) return;
         btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            f();
         }, false, 100);
      }

      private static function showGame(id:int):void
      {
         ServiceContainer.instance.tryGetService("GameManager", function(svc:*, o:Object = null):void
         {
            try { if (svc != null) svc.showGame(id); } catch (e:Error) { RLog.error("scene patch game " + id, e); }
         });
      }

      private static function lift(info:SceneInfo):void
      {
         var btn:InteractiveObject = find(info.scene, "btnLadder") as InteractiveObject;
         if (btn == null) return;
         var here:String = String(info.sceneName);
         btn.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         btn.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            if (menu != null) { closeMenu(); return; }
            showMenu(btn.getBounds(LayerManager.stage), here);
         });
      }

      private static function showMenu(r:Rectangle, here:String):void
      {
         menu = new Sprite();
         menu.name = "liftMenu";
         var w:int = 112, rowH:int = 30, h:int = 30 + FLOORS.length * rowH + 6;
         menu.graphics.lineStyle(2, 0x2E86D6);
         menu.graphics.beginFill(0xEAF6FF, 0.96);
         menu.graphics.drawRoundRect(0, 0, w, h, 14, 14);
         menu.graphics.endFill();
         var title:TextField = label("去哪一层？", 13, 0x1F5F99, true);
         title.x = 8;
         title.y = 5;
         menu.addChild(title);
         for (var i:int = 0; i < FLOORS.length; i++)
         {
            var f:Array = FLOORS[i];
            menu.addChild(floorButton(f, f[1] == here, 8, 30 + i * rowH, w - 16));
         }
         menu.x = Math.max(4, Math.min(960 - w - 4, r.x + r.width / 2 - w / 2));
         menu.y = Math.max(4, r.y - h + 30);
         menu.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         LayerManager.getBaseTop().addChild(menu);
      }

      private static function floorButton(f:Array, current:Boolean, x:Number, y:Number, w:Number):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = "lift_" + f[1];
         b.graphics.beginFill(current ? 0xB8C4CF : 0x4FA8EC);
         b.graphics.drawRoundRect(0, 0, w, 26, 10, 10);
         b.graphics.endFill();
         var t:TextField = label(current ? f[0] + "（这里）" : f[0], 13, 0xFFFFFF, true);
         t.autoSize = "none";
         t.width = w;
         t.height = 22;
         t.x = 0;
         t.y = 3;
         var tf:TextFormat = t.getTextFormat();
         tf.align = "center";
         t.setTextFormat(tf);
         b.addChild(t);
         b.x = x;
         b.y = y;
         if (!current)
         {
            b.buttonMode = true;
            b.useHandCursor = true;
            b.mouseChildren = false;
            b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               e.stopImmediatePropagation();
               closeMenu();
               SceneManager.getInstance().loadScene(f[1], f[2]);
            });
         }
         return b;
      }

      private static function label(s:String, size:int, color:uint, bold:Boolean):TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", size, color, bold);
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = "left";
         t.text = s;
         return t;
      }

      private static function closeMenu():void
      {
         if (menu != null && menu.parent != null) menu.parent.removeChild(menu);
         menu = null;
      }
   }
}
