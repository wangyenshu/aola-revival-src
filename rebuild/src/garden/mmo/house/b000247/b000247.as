package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.housecommon.HouseBase;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.control.IControlService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;
   import mmo.revival.RUI;

   /**
    * REBUILT furniture/b000247: the 家园 (the garden, house 247 of the 2013
    * HouseInfo, where 回家 led first, with 我的家 to the 小屋). Its January 2013
    * SWF is lost (game/ only has a 2017 rework of another garden). What
    * survives of the 2012 one is its picture: the era tutorial
    * house/houseteachmovie/houseteachgarden (January 2012) shows the whole
    * screen, which this uses as the scene (taken out of that SWF at run time,
    * without the tutorial's labels): 亚比仓库, 亚比孵化器, 经验分配器, 我的荣誉, the
    * tube 进入动物园, the 植树盆, 我的家, 留言板, the path 离开花园, and the
    * garden's own bar (地图, 背包, 好友, the friends' list) in place of the
    * control bar. Where the player may walk, and every spot, are drawn over
    * the picture here (RECONSTRUCTED).
    *
    * Working: 我的家 (the main house), 亚比仓库 (pet/petwarehouse), the 植树盆
    * (PlantPanel: the trees of PlantData, drawn from their June 2012
    * pictures plant/y<id>; PlantExtension), 离开花园, 地图, 背包, 好友, 周刊.
    * The others say they are not rebuilt yet.
    */
   public class b000247 extends HouseBase
   {
      private static const NOT_YET:String = "这个功能还在修复中哦！";

      private var pot:Sprite;
      private var treeHolder:Sprite;
      private var tree:Object;
      private var hud:Sprite;
      private var control:IControlService;

      public function b000247()
      {
         super(670, 380);
         addInitLocation("fromHouse", new Point(780, 262));
         name = "garden";
         for each (var n:String in ["obstruction", "background", "overlap", "foreground", "topground"])
         {
            var layer:Sprite = new Sprite();
            layer.name = n;
            addChild(layer);
         }
         drawObstruction(Sprite(getChildByName("obstruction")));
         hud = new Sprite();
         Sprite(getChildByName("topground")).addChild(hud);
         // A second visit finds the picture loaded and puts it at once: everything it needs is made above.
         loadPicture(Sprite(getChildByName("background")));
         // The 植树盆 and its tree (its foot in the pot; the whole of it takes the click).
         pot = new Sprite();
         pot.name = "gardenPot";
         pot.x = 550;
         pot.y = 222;
         pot.graphics.beginFill(0xFFFFFF, 0);
         pot.graphics.drawRect(-58, -150, 116, 162);
         pot.graphics.endFill();
         treeHolder = new Sprite();
         treeHolder.mouseEnabled = treeHolder.mouseChildren = false;
         pot.addChild(treeHolder);
         Sprite(getChildByName("foreground")).addChild(pot);
      }

      /** The tutorial's picture of the garden, without its labels and close button. */
      private function loadPicture(into:Sprite):void
      {
         var cls:String = "mmo.houseteachgarden.GardenTeachMovie";
         var put:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(cls)) return;
            var C:Class = getDefinitionByName(cls) as Class;
            var mc:MovieClip = new C() as MovieClip;
            mc.stop();
            while (mc.numChildren > 1) mc.removeChildAt(mc.numChildren - 1);
            mc.mouseEnabled = mc.mouseChildren = false;
            into.addChild(mc);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(cls)) put();
         else ResScheduler.getResource("house/houseteachmovie/houseteachgarden", put, cls, function(e:* = null):void { RLog.log("garden: no picture"); });
      }

      /** Where one may not walk: everything but the lawn, its paths and the platform of 我的家. */
      private static function drawObstruction(o:Sprite):void
      {
         var g:* = o.graphics;
         g.beginFill(0x000000, 1);
         g.drawRect(-200, -200, 1360, 960);
         var walk:Array = [150,262, 300,226, 455,268, 560,236, 650,232, 700,252, 760,244, 880,242, 905,286, 790,300, 712,322,
            748,396, 700,430, 560,424, 420,432, 300,428, 190,402, 122,352, 112,292];
         g.moveTo(walk[0], walk[1]);
         for (var i:int = 2; i < walk.length; i += 2) g.lineTo(walk[i], walk[i + 1]);
         g.lineTo(walk[0], walk[1]);
         g.endFill();
         o.alpha = 0;
      }

      override protected function onJoinRoom():void
      {
         super.onJoinRoom();
         try
         {
            control = ServiceContainer.getService(IControlService) as IControlService;
            if (control != null) control.hide();
         }
         catch (e:Error) {}
         nameplates();
         taskIconOverPicture(true);
         var fg:Sprite = Sprite(getChildByName("foreground"));
         // Things of the garden: walk there, then act.
         spot(fg, 735, 95, 155, 140, 800, 266, "我的家", function():void { if (loader != null) loader.loadSubHouse(-1, "default"); });
         spot(fg, 62, 168, 80, 70, 160, 286, "亚比仓库", function():void { panel("PetWareHouse"); });
         spot(fg, 0, 0, 0, 0, 548, 262, "植树盆", openPot, pot);
         spot(fg, 600, 336, 140, 92, 680, 400, "离开花园", leaveHome);
         // The era 亚比孵化器 panel (pet/pethatchegg; the server's PetEggExtension, eggs.ts).
         spot(fg, 72, 248, 80, 72, 165, 320, "亚比孵化器", function():void { if (isMine()) panel("PetHatchEgg"); else notYet(); });
         spot(fg, 248, 198, 76, 94, 285, 300, "经验分配器", notYet);
         spot(fg, 128, 66, 116, 104, 200, 270, "我的荣誉", notYet);
         spot(fg, 330, 20, 110, 172, 390, 270, "进入动物园", notYet);
         spot(fg, 782, 288, 100, 84, 700, 335, "留言板", notYet);
         // The garden's bar (the control bar is put away here, as in 2012).
         button(28, 386, 70, 54, "地图", function():void
         {
            SimpleCustomLoader.loadSingleResource("map/map", "mmo.map.AolaMapService", LoadingSpriteType.DIALOG, "正在加载地图……",
               function(p:Object):void { if (p is IShowPanel) IShowPanel(p).showPanel(); });
         });
         button(106, 392, 46, 48, "背包", function():void { panel("NewPetPackage"); });
         button(158, 392, 54, 48, "好友", function():void { panel("BuddyListService"); });
         button(12, 8, 52, 50, "周刊", function():void
         {
            ServiceContainer.instance.tryGetService("WeeklyService", function(svc:IService, o:Object):void
            {
               try { Object(svc).showLastestWeekly(); } catch (e:Error) { RLog.error("garden weekly", e); }
            });
         });
         button(72, 8, 52, 50, "邮箱", notYet);
         button(132, 8, 52, 50, "勋章", notYet);
         button(190, 8, 52, 50, "相册", notYet);
         button(770, 8, 52, 50, "图鉴", notYet);
         button(826, 8, 52, 50, "游戏", notYet);
         button(904, 164, 50, 50, "放映厅", notYet);
         button(904, 216, 50, 50, "健身房", notYet);
         button(904, 268, 50, 50, "最近访问", notYet);
         SocketClient.instance.addEventListener("revival_garden", onGarden);
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_garden", {op: "info", un: owner()});
      }

      override protected function onLeaveRoom():void
      {
         SocketClient.instance.removeEventListener("revival_garden", onGarden);
         PlantPanel.closeIfOpen();
         taskIconOverPicture(false);
         if (control != null) control.show();
         super.onLeaveRoom();
      }

      /**
       * The picture shows the 任务 button where the game's own one (taskpanelnew,
       * "taskIcon" at 912, 8) stands a little off: in the garden the live
       * button is laid exactly over the drawn one.
       */
      private static function taskIconOverPicture(over:Boolean):void
      {
         try
         {
            var icon:DisplayObject = LayerManager.getBaseControl().getChildByName("taskIcon");
            if (icon == null) return;
            icon.x = over ? 879 : 912;
            icon.y = over ? -2 : 8;
         }
         catch (e:Error) {}
      }

      private function owner():String
      {
         try { return loader.houseInfo.owner; } catch (e:Error) {}
         return SocketClient.instance.myUserName;
      }

      /** The owner's name on the plates the picture shows "小奥拉" on (top middle, the friends' list). */
      private function nameplates():void
      {
         var who:String = owner();
         try { if (loader.houseInfo.desc) who = loader.houseInfo.desc; } catch (e:Error) {}
         plate(412, 6, 116, 20, 0x1C5D9B, who, 0xFFFFFF);
         plate(16, 455, 88, 18, 0xF2B21B, who, 0x8A3B00);
         // The tutorial's sample friend in the friends' list: the list stays empty here.
         var cover:Sprite = new Sprite();
         cover.mouseEnabled = false;
         cover.graphics.beginFill(0x31C9FB);
         cover.graphics.drawRoundRect(158, 450, 98, 106, 10, 10);
         cover.graphics.endFill();
         hud.addChild(cover);
      }

      private function plate(x:int, y:int, w:int, h:int, fill:uint, text:String, color:uint):void
      {
         var p:Sprite = new Sprite();
         p.mouseEnabled = p.mouseChildren = false;
         p.graphics.beginFill(fill);
         p.graphics.drawRoundRect(x, y, w, h, 8, 8);
         p.graphics.endFill();
         var t:TextField = RUI.text(13, color, true);
         t.text = text;
         t.x = x + (w - t.width) / 2;
         t.y = y + (h - t.height) / 2;
         p.addChild(t);
         hud.addChild(p);
      }

      /**
       * A thing of the garden: a click on it (the rectangle x, y, w, h over
       * its picture, or the given sprite) walks the player to where one
       * stands before it (sx, sy, on the lawn), then act() runs.
       */
      private function spot(into:Sprite, x:int, y:int, w:int, h:int, sx:int, sy:int, tip:String, act:Function, clickable:Sprite = null):void
      {
         var stand:Sprite = new Sprite();
         stand.name = "gardenStand_" + tip;
         stand.graphics.beginFill(0xFFFFFF, 0);
         stand.graphics.drawRect(-6, -6, 12, 12);
         stand.graphics.endFill();
         stand.x = sx;
         stand.y = sy;
         into.addChild(stand);
         if (clickable == null)
         {
            clickable = new Sprite();
            clickable.graphics.beginFill(0xFFFFFF, 0);
            clickable.graphics.drawRect(0, 0, w, h);
            clickable.graphics.endFill();
            clickable.x = x;
            clickable.y = y;
            into.addChild(clickable);
         }
         clickable.name = "garden_" + tip;
         try { TipsManager.getInstance().addTips(clickable, tip); } catch (e:Error) {}
         addEntranceAction(stand, act, clickable);
      }

      private function button(x:int, y:int, w:int, h:int, tip:String, act:Function):void
      {
         var b:Sprite = new Sprite();
         b.name = "gardenBtn_" + tip;
         b.buttonMode = true;
         b.graphics.beginFill(0xFFFFFF, 0);
         b.graphics.drawRect(0, 0, w, h);
         b.graphics.endFill();
         b.x = x;
         b.y = y;
         b.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            act();
         });
         try { TipsManager.getInstance().addTips(b, tip); } catch (e2:Error) {}
         hud.addChild(b);
      }

      private static function panel(service:String):void
      {
         ServiceContainer.instance.tryGetService(service, function(svc:IService, o:Object):void
         {
            try { IShowPanel(svc).showPanel(); } catch (e:Error) { RLog.error("garden " + service, e); }
         });
      }

      private static function notYet():void
      {
         RNotice.show(LayerManager.getBaseTop(), NOT_YET);
      }

      private function isMine():Boolean
      {
         try { return loader.isMyHouse; } catch (e:Error) {}
         return true;
      }

      private function openPot():void
      {
         PlantPanel.show(owner(), isMine(), tree, showTree);
      }

      private function onGarden(e:SocketClientEvent):void
      {
         showTree(e.params.plant);
      }

      /** The tree in the 植树盆 as it has grown (plant/y<id>, TreeArt). */
      private function showTree(t:Object):void
      {
         tree = t != null && int(t.id) > 0 ? t : null;
         while (treeHolder.numChildren) treeHolder.removeChildAt(0);
         if (tree == null) return;
         var id:int = int(tree.plantId);
         var index:int = TreeArt.pictureIndex(id, int(tree.level), int(tree.remainFruit) > 0);
         var shown:Object = tree;
         TreeArt.load(id, "_C", function(C:Class):void
         {
            if (shown != tree) return;
            var pic:DisplayObject = TreeArt.picture(C, index);
            if (pic == null) return;
            while (treeHolder.numChildren) treeHolder.removeChildAt(0);
            var shownTree:Sprite = TreeArt.fit(pic, 150, 160);
            shownTree.name = "gardenTree";
            treeHolder.addChild(shownTree);
         });
      }
   }
}
