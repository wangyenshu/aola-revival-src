package mmo.treemanager.treepanel
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.DateUtil;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.TreeClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.material.MaterialServiceEvent;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.plant.IPlantService;
   import mmo.interfaces.material.plant.Plant;
   import mmo.interfaces.material.plant.PlantLevel;
   import mmo.interfaces.material.plantitem.IPlantItemService;
   import mmo.interfaces.material.plantitem.PlantItem;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.materialdata.PlantData;
   import mmo.revival.RLog;

   /**
    * REBUILT tree panel of the 植树盆 (yz/treemanager's TreePanel, the later copy's code on its
    * art, symbol 290; the panels it opens are yz/panel_res's of April 2012). Over the tree it
    * shows its level, 健康值 and 营养值 and the buttons: 雨露 and 养料 (50 晶币 each for the
    * owner, free for a visitor), 采摘, 道具 (the 盆栽道具, SelectPlantToolPanel), 种植手册, 守护亚比
    * (蓝宝石: GuardYabiPanel) and 收为家具 (into the 小屋's storage: yz/plantdecorator); for the
    * owner, 植物心声 (who cared for it). The commands are the 2013 TreeClient's (PlantExtension
    * 80_3, 80_4, 80_5, 80_12, 80_14; 81_1 for the 道具), the server's plants.ts. The garden's tree is not one of the house's plant views:
    * the garden passes its tree, its picture and what to do when it changes.
    */
   public class TreePanel extends Sprite
   {
      private static const RES:String = "yz/panel_res";
      private static var current:TreePanel;

      public var btnPlantCatlog:SimpleButton;
      public var btnTool:SimpleButton;
      public var tmpPlace:MovieClip;
      public var btnSetFurniture:SimpleButton;
      public var lvlMc:MovieClip;
      public var btnYabi:SimpleButton;
      public var btnFat:SimpleButton;
      public var btnRain:SimpleButton;
      public var panelbase:MovieClip;
      public var btnSteal:SimpleButton;

      private var tree:Object;
      private var owner:String;
      private var mine:Boolean;
      private var view:DisplayObject;
      private var onChange:Function;
      private var visit:Function;
      private var plant:Plant;
      private var levels:Array = [];
      private var busy:Boolean;
      private var levelUp:Boolean;
      private var item:PlantItem;
      private var visitors:VisitorPanel;
      private var icon:DisplayObject;

      /**
       * The panel for the garden's tree (tree: the server's plant), by its picture (view) in host.
       * onChange(tree or null): the tree as it is now (null: dug up); visit(name): to that home.
       */
      public static function show(host:DisplayObjectContainer, view:DisplayObject, tree:Object, owner:String, mine:Boolean, onChange:Function, visit:Function = null):void
      {
         if (current != null && current.tree != null && tree != null && current.tree.id == tree.id && current.parent == host)
         {
            current.update(tree);
            current.visible = true;
            current.place();
            return;
         }
         hide();
         if (tree == null || host == null || view == null) return;
         current = new TreePanel(tree, owner, mine, view, onChange, visit);
         host.addChild(current);
         current.place();
      }

      public static function hide():void
      {
         if (current != null) current.dispose();
         current = null;
      }

      public function TreePanel(tree:Object, owner:String, mine:Boolean, view:DisplayObject, onChange:Function, visit:Function)
      {
         super();
         name = "treePanel";
         this.owner = owner;
         this.mine = mine;
         this.view = view;
         this.onChange = onChange;
         this.visit = visit;
         panelbase.x = -7.2;
         panelbase.y = -63.4;
         lvlMc.x = 24.6;
         update(tree);
         tips();
         listen();
         if (mine)
         {
            visitors = new VisitorPanel(String(tree.visitors || ""), visit);
            visitors.x = 5;
            visitors.y = -15;
            addChildAt(visitors, getChildIndex(tmpPlace) + 1);
         }
         else
         {
            btnYabi.visible = false;
            btnPlantCatlog.visible = false;
            btnSetFurniture.visible = false;
         }
         addEventListener(Event.ENTER_FRAME, watch);
      }

      /** Beside the tree, as TreeManager put it (left of it near the right edge). */
      private function place():void
      {
         if (parent == null || view.stage == null) return;
         var b:Rectangle = view.getBounds(parent);
         if (mine)
         {
            y = Math.max(120, Math.min(380, b.top + b.height * 0.2));
            if (b.right > 700)
            {
               x = b.left - 220;
               tmpPlace.x = 125;
            }
            else
            {
               x = b.right - b.width * 0.1;
               tmpPlace.x = 0;
            }
         }
         else
         {
            x = b.left - 200 + b.width * 0.2;
            y = Math.max(120, Math.min(380, b.top + b.height * 0.2));
            tmpPlace.x = 0;
            tmpPlace.y = 0;
         }
      }

      /** Gone when the pointer leaves the tree and the panel (TreeManager's onEnterframe), unless a film or a dialog is up. */
      private function watch(e:Event):void
      {
         if (!visible || busy || stage == null) return;
         var mx:Number = stage.mouseX, my:Number = stage.mouseY;
         if (!hitTestPoint(mx, my, false) && !view.hitTestPoint(mx, my, false)) visible = false;
      }

      private function update(t:Object):void
      {
         tree = t;
         var id:int = int(t.plantId);
         plant = PlantData.data[String(id)] as Plant;
         levels = [];
         for each (var l:PlantLevel in PlantData.level) if (l.plantId == id) levels[l.level] = l;
         setPanel();
         setSteal();
         setFurniture();
         setIcon(id);
      }

      private function get maxLevel():int
      {
         return plant != null ? plant.maxlevel : levels.length - 1;
      }

      private function setPanel():void
      {
         var lv:int = int(tree.level);
         var info:PlantLevel = levels[lv] as PlantLevel;
         var health:TextField = panelbase.getChildByName("txtHealth") as TextField;
         var food:TextField = panelbase.getChildByName("txtNutrition") as TextField;
         var rain:MovieClip = panelbase.getChildByName("lvlRain") as MovieClip;
         var fat:MovieClip = panelbase.getChildByName("lvlFat") as MovieClip;
         if (lv < maxLevel && info != null && info.maxHealth > 0)
         {
            var h:int = Math.min(int(tree.health), info.maxHealth);
            var n:int = Math.min(int(tree.nutrition), info.maxNutrition);
            if (health) { health.visible = true; health.text = h + "/" + info.maxHealth; }
            if (food) { food.visible = true; food.text = n + "/" + info.maxNutrition; }
            if (rain) rain.gotoAndStop(Math.max(1, int(100 * h / info.maxHealth)));
            if (fat) fat.gotoAndStop(Math.max(1, int(100 * n / Math.max(1, info.maxNutrition))));
         }
         else
         {
            if (health) health.visible = false;
            if (food) food.visible = false;
            if (rain) rain.gotoAndStop(rain.totalFrames);
            if (fat) fat.gotoAndStop(fat.totalFrames);
         }
         lvlMc.gotoAndStop(lv + 1);
      }

      private function setIcon(id:int):void
      {
         if (icon != null) return;
         var service:IPlantService = ServiceContainer.getService(IPlantService) as IPlantService;
         if (service == null) return;
         var put:Function = function(v:DisplayObject):void
         {
            if (v == null || icon != null) return;
            icon = v;
            DisplayUtil.scaleDisplay(v, 23, 23);
            v.x = -18;
            v.y = -2;
            lvlMc.addChildAt(v, 0);
         };
         var got:Function = function(e:MaterialServiceEvent):void
         {
            if (int(e.params.id) != id) return;
            service.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(e.params.view as DisplayObject);
         };
         service.addEventListener(MaterialServiceEvent.onGetView, got);
         var v:DisplayObject = null;
         try { v = service.getView(id); } catch (err:Error) { RLog.error("tree icon", err); }
         if (v != null)
         {
            service.removeEventListener(MaterialServiceEvent.onGetView, got);
            put(v);
         }
      }

      private function tips():void
      {
         var tm:TipsManager = TipsManager.getInstance();
         var tr:DisplayObject = panelbase.getChildByName("tipsRain");
         var tn:DisplayObject = panelbase.getChildByName("tipsNur");
         if (tr is InteractiveObject) tm.addComplexTips(InteractiveObject(tr), "", "健康值");
         if (tn is InteractiveObject) tm.addComplexTips(InteractiveObject(tn), "", "营养值");
         tm.addComplexTips(btnRain, "", "雨露");
         tm.addComplexTips(btnFat, "", "养料");
         tm.addComplexTips(btnPlantCatlog, "", "种植手册");
         tm.addComplexTips(btnTool, "", "道具");
         tm.addComplexTips(btnYabi, "", member() ? "守护亚比" : "只有蓝宝石才可以设置守护亚比！");
      }

      private static function member():Boolean
      {
         try { return MemberManager.instance.isMember(); } catch (e:Error) {}
         return false;
      }

      private function listen():void
      {
         btnRain.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopImmediatePropagation(); care(true); });
         btnFat.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopImmediatePropagation(); care(false); });
         btnSteal.addEventListener(MouseEvent.CLICK, onSteal);
         btnTool.addEventListener(MouseEvent.CLICK, onTool);
         btnPlantCatlog.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopImmediatePropagation();
            ServiceContainer.instance.tryGetService("SellBookService", function(svc:IBookClubService, o:Object = null):void { svc.showPage("catalog201102"); });
         });
         if (member()) btnYabi.addEventListener(MouseEvent.CLICK, onYabi);
         else DisplayUtil.applyGray(btnYabi);
      }

      /** 采摘: with fruit on the tree; else why not, or when the next comes. */
      private function setSteal():void
      {
         var tm:TipsManager = TipsManager.getInstance();
         tm.removeTips(btnSteal);
         if (int(tree.remainFruit) > 0)
         {
            btnSteal.mouseEnabled = true;
            DisplayUtil.clearFilters(btnSteal);
            tm.addComplexTips(btnSteal, "", "采摘");
            return;
         }
         DisplayUtil.applyGray(btnSteal);
         var lv:int = int(tree.level);
         if (int(tree.remainProductTime) <= 0)
         {
            if (plant != null && lv < plant.matruelev) tm.addComplexTips(btnSteal, "", "小树还没有成熟，还不可以结果哦！");
            else if (lv < maxLevel) tm.addComplexTips(btnSteal, "", "在提升至下个等级之前，这棵树都不会结果啦！");
            else tm.addComplexTips(btnSteal, "", "这棵树已经耗尽了营养，结不出果实了！");
         }
         else
         {
            var next:Date = new Date(Number(tree.nextFruitTime));
            var now:Date = new Date();
            try { now = DateUtil.getServerTime(); } catch (err:Error) {}
            tm.addComplexTips(btnSteal, "下次结果时间为" + (next.date == now.date ? "今" : "明") + "天" + next.hours + "：00，还可以结果" + int(tree.remainProductTime) + "次", "");
         }
      }

      /** 收为家具: the owner's, at the top level with no fruit to come. */
      private function setFurniture():void
      {
         if (!mine) return;
         var tm:TipsManager = TipsManager.getInstance();
         tm.removeTips(btnSetFurniture);
         btnSetFurniture.removeEventListener(MouseEvent.CLICK, onFurniture);
         if (int(tree.level) < maxLevel)
         {
            DisplayUtil.applyGray(btnSetFurniture);
            tm.addComplexTips(btnSetFurniture, "", "未达到满级不能收为家具");
         }
         else if (int(tree.remainFruit) <= 0 && int(tree.remainProductTime) <= 0)
         {
            DisplayUtil.clearFilters(btnSetFurniture);
            tm.addComplexTips(btnSetFurniture, "", "收为家具");
            btnSetFurniture.addEventListener(MouseEvent.CLICK, onFurniture);
         }
         else
         {
            DisplayUtil.applyGray(btnSetFurniture);
            tm.addComplexTips(btnSetFurniture, "", "这棵树还能结果，不能收为家具");
         }
      }

      /**
       * 收为家具: the grown tree out of the 植树盆 and into the 我的家具 storage of the 小屋
       * (the rebuilt yz/plantdecorator puts it down there); the pot is free again.
       */
      private function onFurniture(e:MouseEvent):void
      {
         e.stopImmediatePropagation();
         if (busy) return;
         busy = true;
         var d:ModalDialog = NewDialog.getCofirmDialog("你确定将这颗树收为家具吗？", null, null, NewDialog.getSucceedIcon());
         d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void
         {
            SocketClient.instance.addEventListener(TreeClient.cmdSetFurniture, onSetFurniture);
            TreeClient.instance.sendSetFurniture(int(tree.id));
         });
         d.addEventListener(ModalDialogEvent.CANCEL, function(ev:ModalDialogEvent):void { busy = false; });
         d.addEventListener(ModalDialogEvent.CLOSE, function(ev:ModalDialogEvent):void { busy = false; });
         d.show();
      }

      private function onSetFurniture(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(TreeClient.cmdSetFurniture, onSetFurniture);
         busy = false;
         if (!e.params.res)
         {
            NewDialog.showFailMessage("这棵树还不能收为家具哦！");
            return;
         }
         NewDialog.showSucceedMessage("恭喜你，一个" + plant.name + "家具已经放入你的空间舱装扮！");
         var f:Function = onChange;
         hide();
         if (f != null) f(null);
      }

      // ---------------------------------------------------------------- 雨露, 养料

      private function care(rain:Boolean):void
      {
         if (busy) return;
         var cmd:String = rain ? TreeClient.cmdAddHealth : TreeClient.cmdAddNutrition;
         var send:Function = function():void
         {
            busy = true;
            SocketClient.instance.addEventListener(cmd, onCare);
            if (rain) TreeClient.instance.addHealth(owner, int(tree.id));
            else TreeClient.instance.addNutrition(owner, int(tree.id));
         };
         if (!mine) { send(); return; }
         busy = true;
         var d:ModalDialog = NewDialog.getCofirmDialog((rain ? "添加雨露" : "添加养料") + "需要50晶币，你确定继续吗？", null, null, NewDialog.getSucceedIcon());
         d.addEventListener(ModalDialogEvent.OK, function(ev:ModalDialogEvent):void { send(); });
         d.addEventListener(ModalDialogEvent.CANCEL, function(ev:ModalDialogEvent):void { busy = false; });
         d.addEventListener(ModalDialogEvent.CLOSE, function(ev:ModalDialogEvent):void { busy = false; });
         d.show();
      }

      private function onCare(e:SocketClientEvent):void
      {
         var rain:Boolean = e.type == TreeClient.cmdAddHealth;
         SocketClient.instance.removeEventListener(e.type, onCare);
         var r:Object = e.params.result || {};
         if (int(r.result) < 0)
         {
            busy = false;
            wrong(rain ? 1 : 2, int(r.result));
            return;
         }
         levelUp = int(r.result) == 1;
         changed(r.userPlant);
         play(rain ? new AddHealthMovie() : new Nutrtion(), afterFilm);
      }

      // ---------------------------------------------------------------- 采摘

      private function onSteal(e:MouseEvent):void
      {
         e.stopImmediatePropagation();
         if (busy || int(tree.remainFruit) <= 0) return;
         busy = true;
         SocketClient.instance.addEventListener(TreeClient.cmdPick, onPick);
         TreeClient.instance.pick(owner, int(tree.id));
      }

      private function onPick(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(TreeClient.cmdPick, onPick);
         var r:Object = e.params.result || {};
         var code:int = int(r.result);
         if (code != 0 && code != 2)
         {
            busy = false;
            if (code == -22) code = int(tree.remainFruit) <= 1 ? -10 : -11;
            if (r.userPlant) changed(r.userPlant);
            wrong(3, code);
            return;
         }
         play(new Pickfruit(), function():void
         {
            busy = false;
            var n:int = int(r.extData);
            if (mine) NewDialog.showSucceedMessage("你成功收获了" + n + "个" + fruitName());
            else if (int(tree.petId) == 0) NewDialog.showSucceedMessage("你成功摘走了" + n + "个" + fruitName());
            else NewDialog.showSucceedMessage("守护亚比正在一旁打盹呢，你悄悄的摘走了" + n + "个" + fruitName());
            changed(r.userPlant);
         });
      }

      private function fruitName():String
      {
         try { return (ServiceContainer.getService(IItemService) as IItemService).getItemById(plant.fruitId).name; } catch (e:Error) {}
         return "果实";
      }

      // ---------------------------------------------------------------- 道具, 守护亚比

      /** A class of yz/panel_res (rebuilt), the module loaded first. */
      private static function res(cls:String, then:Function):void
      {
         var full:String = "mmo.treemanager.treepanel." + cls;
         var go:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(full)) { RLog.log("tree: no " + full); then(null); return; }
            then(ApplicationDomain.currentDomain.getDefinition(full) as Class);
         };
         if (ApplicationDomain.currentDomain.hasDefinition(full)) go();
         else ResScheduler.getResource(RES, go, "", function(e:* = null):void { RLog.log("tree: yz/panel_res not loaded"); then(null); });
      }

      private function onTool(e:MouseEvent):void
      {
         e.stopImmediatePropagation();
         if (busy) return;
         busy = true;
         res("SelectPlantToolPanel", function(C:Class):void
         {
            if (C == null) { busy = false; return; }
            var p:Sprite = new C(mine, function(toolId:int):void
            {
               busy = false;
               if (toolId > 0) useTool(toolId);
            }) as Sprite;
            ModalDialogManager.getInstance().addModalDialog(p);
         });
      }

      private function useTool(id:int):void
      {
         var service:IPlantItemService = ServiceContainer.getService(IPlantItemService) as IPlantItemService;
         item = service != null ? service.getPlantItemById(id) : null;
         busy = true;
         SocketClient.instance.addEventListener("81_1", onUsed);
         SocketClient.instance.sendXtMessage("PlantItemExtension", "81_1", {itemId: id, userPlantId: int(tree.id), quantity: 1, owner: owner});
      }

      private function onUsed(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener("81_1", onUsed);
         var r:Object = e.params.result || {};
         if (int(r.result) < 0)
         {
            busy = false;
            wrong(5, int(r.result));
            return;
         }
         var id:int = item != null ? item.id : 0;
         if (int(r.dug) == 1)
         {
            play(new UseTool7(), function():void
            {
               busy = false;
               var f:Function = onChange;
               hide();
               if (f != null) f(null);
            });
            return;
         }
         levelUp = int(r.result) == 1;
         if (r.userPlant) changed(r.userPlant);
         var film:UseTool = new UseTool();
         if (film.add10health) film.add10health.visible = id == 1;
         if (film.add10nutrition) film.add10nutrition.visible = id == 2;
         play(film, function():void
         {
            if (id == 3 || id == 4)
               NewDialog.showSucceedMessage("你对" + plant.name + "使用了" + item.name + "，" + plant.name + (id == 3 ? "健康值" : "营养值") + "每日成长上限增加为" + int(id == 3 ? tree.healthCeil : tree.nutritionCeil) + "。");
            afterFilm();
         });
      }

      private function onYabi(e:MouseEvent):void
      {
         e.stopImmediatePropagation();
         if (busy) return;
         busy = true;
         res("GuardYabiPanel", function(C:Class):void
         {
            if (C == null) { busy = false; return; }
            var p:Sprite = new C(int(tree.petId), function(petId:int):void
            {
               busy = false;
               if (petId < 0) return;
               SocketClient.instance.addEventListener(TreeClient.cmdSetYabi, onSetYabi);
               TreeClient.instance.setYabi(int(tree.id), petId);
            }) as Sprite;
            ModalDialogManager.getInstance().addModalDialog(p);
         });
      }

      private function onSetYabi(e:SocketClientEvent):void
      {
         SocketClient.instance.removeEventListener(TreeClient.cmdSetYabi, onSetYabi);
         var r:Object = e.params.result || {};
         if (int(r.result) != 0)
         {
            wrong(6, int(r.result));
            return;
         }
         changed(r.userPlant);
         NewDialog.showSucceedMessage(int(tree.petId) > 0 ? "设置守护亚比成功" : "已经取消守护亚比了");
      }

      // ---------------------------------------------------------------- films

      /** A film over the foot of the tree, played once, then then(). */
      private function play(film:MovieClip, then:Function):void
      {
         var at:Point = moviePoint();
         ModalDialogManager.getInstance().addModalDialog(film, AlignType.NONE, 0, false, at.x, at.y);
         film.gotoAndPlay(1);
         var last:int = film.totalFrames;
         var tick:Function = function(e:Event):void
         {
            if (film.currentFrame < last && film.parent != null) return;
            film.removeEventListener(Event.ENTER_FRAME, tick);
            film.stop();
            ModalDialogManager.getInstance().removeModalDialog(film);
            try { then(); } catch (err:Error) { RLog.error("tree film", err); }
         };
         film.addEventListener(Event.ENTER_FRAME, tick);
      }

      private function afterFilm():void
      {
         busy = false;
         if (!levelUp) return;
         levelUp = false;
         var up:LevelUp = new LevelUp();
         play(up, function():void {});
         var down:LevelUpDown = new LevelUpDown();
         var holder:DisplayObjectContainer = view as DisplayObjectContainer;
         if (holder != null)
         {
            holder.addChildAt(down, 0);
            down.y = 20;
            var tick:Function = function(e:Event):void
            {
               if (down.currentFrame < down.totalFrames) return;
               down.removeEventListener(Event.ENTER_FRAME, tick);
               down.stop();
               if (down.parent != null) down.parent.removeChild(down);
            };
            down.addEventListener(Event.ENTER_FRAME, tick);
         }
      }

      private function moviePoint():Point
      {
         var b:Rectangle = view.getBounds(view);
         return view.localToGlobal(new Point((b.left + b.right) / 2, b.bottom));
      }

      private function changed(t:Object):void
      {
         if (t == null) return;
         update(t);
         if (onChange != null) onChange(t);
      }

      /** The 2013 panel's words for what the server refused (ShowPanelHelper.showWrongPanel). */
      private function wrong(what:int, code:int):void
      {
         var n:String = plant != null ? plant.name : "树";
         var say:String = null;
         switch (code)
         {
            case -1: say = what == 6 ? "你还没有设置守护亚比呢！" : "树上的果实已经被摘光了！"; break;
            case -2: say = "很抱歉，你的晶币余额不足，目前你拥有" + UserInfo.score + "晶币。"; break;
            case -3: say = "道具数量不足！"; break;
            case -4: say = n + "增加的" + (what == 1 ? "健康值" : "营养值") + "已经达到上限，请明天再来。"; break;
            case -5:
               if (what == 1) say = "你每天只能为这棵" + n + "添加两次雨露哦！";
               else if (what == 2) say = "你每天只能为这棵" + n + "添加两次养料哦！";
               else if (what == 3) say = "今天摘那么多棵树了，见好要收呀！";
               else if (item != null && (item.id == 5 || item.useType == 3)) say = "在下次结果之前不能再对这棵" + n + "使用这个道具了！";
               else if (item != null && item.useType == 1) say = "今天已经不能使用这个道具了哦！";
               else say = "你已经不能对这棵" + n + "使用这个道具了！";
               break;
            case -8: say = "没有这个亚比哦！"; break;
            case -9: say = "这棵" + n + "已经达到最高级了呀"; break;
            case -10: say = "就这么点果实，摘它我还嫌费力气呢……"; break;
            case -11: say = "做人不能贪得无厌呀！去拿别人的吧！"; break;
            case -14: say = "守护亚比发现了你，还是赶紧溜吧！"; break;
            case -16: say = "你身上已经拥有很多果实了！"; break;
            case -17:
               var health:Boolean = what == 1 || (what == 5 && item != null && item.id == 1);
               say = n + "的" + (health ? "健康值" : "营养值") + "是有上限的，在到达下一等级之前已经不能增加了！";
               break;
            case -18: say = n + "还不会结果，这个道具对它不起任何作用！"; break;
            case -19: say = "这棵植物可能已经被铲走了呀！"; break;
            case -20: say = "你不能铲走别人的植物哦!"; break;
         }
         if (say != null) NewDialog.showFailMessage(say);
      }

      public function dispose():void
      {
         removeEventListener(Event.ENTER_FRAME, watch);
         SocketClient.instance.removeEventListener(TreeClient.cmdAddHealth, onCare);
         SocketClient.instance.removeEventListener(TreeClient.cmdAddNutrition, onCare);
         SocketClient.instance.removeEventListener(TreeClient.cmdPick, onPick);
         SocketClient.instance.removeEventListener("81_1", onUsed);
         SocketClient.instance.removeEventListener(TreeClient.cmdSetYabi, onSetYabi);
         if (parent != null) parent.removeChild(this);
      }
   }
}
