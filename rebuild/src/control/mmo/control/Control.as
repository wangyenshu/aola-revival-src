package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.display.Sprite;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.face.IFaceService;
   import mmo.play.action.ActionHelper;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.control.IControlService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT. The "Control" service of ServiceConfig (mmo.control.Control in
    * control/control): the control bar at the bottom of the screen.
    *
    * The 2013 bar's artwork was in the lost control.swf, so the bar
    * (ControlBar) is laid out after the official screenshot of the bar of
    * December 2011. Its buttons open the services the 2013 client had:
    * map/map (mmo.map.AolaMapService), the quick phrases of config.xml,
    * FaceService, the avatar's sitting actions, UserCardService,
    * BuddyListService, TeamService, SquadService, NewPetPackage, the home
    * through HouseService.houseLoader.
    */
   public class Control extends EventDispatcher implements IControlService
   {
      private var bar:ControlBar;
      private var fbMode:Boolean;
      private var _fbLeave:InteractiveObject;
      private var _fbMap:InteractiveObject;

      public function Control()
      {
         super();
      }

      public function init():void
      {
         bar = new ControlBar();
         bar.onButton = onButton;
         bar.onSay = function(text:String):void
         {
            ServiceContainer.instance.tryGetService("SceneTalkService", function(svc:IService, o:Object):void
            {
               Object(svc).say(text);
            });
         };
         LayerManager.getBaseControl().addChild(bar);
         SocketClient.instance.addEventListener(SocketClientEvent.onJoinRoom, function(e:SocketClientEvent):void { bar.closePopup(); });
         installDebugHook();
         SceneManager.getInstance().loadDefaultScene();
      }

      private function onButton(name:String):void
      {
         switch (name)
         {
            case "map":
               openMap();
               break;
            case "phrase":
               showPhrases();
               break;
            case "face":
               showFaces();
               break;
            case "action":
               showActions();
               break;
            case "history":
               ServiceContainer.instance.tryGetService("SceneTalkService", function(svc:IService, o:Object):void
               {
                  bar.togglePopup(new TalkHistoryPanel(Object(svc).getTalkMessageRec()), 360, 520, bar.getChildByName("mctalkbar"));
               });
               break;
            case "card":
               // The January 2013 player card, with the wardrobe (usercard_res_clothes).
               ServiceContainer.instance.tryGetService("UserCardService", function(svc:IService, o:Object):void
               {
                  Object(svc).showUserCard(SocketClient.instance.myUserName, 1);
               });
               break;
            case "pet":
               // 背包 of the December 2011 bar: the 亚比背包 (NewBieSystemConfig: 亚比背包 at x 790).
               showPanel("NewPetPackage");
               break;
            case "home":
               goHome();
               break;
            case "friend":
               showPanel("BuddyListService");
               break;
            case "team":
               showPanel("TeamService");
               break;
            case "squad":
               showPanel("SquadService");
               break;
            case "shoot":
               RNotice.show(LayerManager.getBaseTop(), "射击要用光能石，射线功能还在修复中哦！");
               break;
            case "mall":
               RNotice.show(LayerManager.getBaseTop(), "商城还在修复中，敬请期待！");
               break;
            default:
               RNotice.show(LayerManager.getBaseTop(), "这个功能还在修复中哦！");
         }
      }

      /** 发言: the quick phrases of config.xml (message/phrases). */
      private function showPhrases():void
      {
         var list:XMLList;
         try { list = ConfigReader.instance.xmlDocument.message.phrases; } catch (e:Error) { RLog.error("phrases", e); }
         if (list == null || list.length() == 0) return;
         var p:PhrasePanel = new PhrasePanel(list);
         p.onPhrase = function(text:String):void
         {
            bar.closePopup();
            SocketClient.instance.sendPhrase(text);
         };
         bar.togglePopup(p, 150, 512, bar.button("phrase"));
      }

      /** 表情: the faces of baseservice/face. */
      private function showFaces():void
      {
         ServiceContainer.instance.tryGetService("FaceService", function(svc:IService, o:Object):void
         {
            var p:FacePanel = new FacePanel(svc as IFaceService);
            p.onFace = function(id:int):void
            {
               bar.closePopup();
               ServiceContainer.instance.tryGetService("SceneTalkService", function(talk:IService, o2:Object):void
               {
                  Object(talk).smile(id);
               });
            };
            bar.togglePopup(p, 232 - p.width / 2, 512, bar.button("face"));
         });
      }

      /** 动作: sit down, facing one of four ways. */
      private function showActions():void
      {
         var p:ActionPanel = new ActionPanel();
         p.onAction = function(code:String):void
         {
            bar.closePopup();
            var me:PlayerBase = PlayerManager.getInstance().myPlayer;
            if (me == null) return;
            me.stop();
            ActionHelper.Instance.doAction(code, me);
         };
         bar.togglePopup(p, 277 - p.width / 2, 512, bar.button("action"));
      }

      public static function openMap():void
      {
         SimpleCustomLoader.loadSingleResource("map/map", "mmo.map.AolaMapService", LoadingSpriteType.DIALOG, "正在加载地图……",
            function(p:IShowPanel):void { p.showPanel(); });
      }

      public static function goHome():void
      {
         ServiceContainer.instance.tryGetService("HouseService", function(svc:IService, o:Object):void
         {
            var loader:Object = null;
            try { loader = Object(svc).houseLoader; } catch (e:Error) {}
            if (loader == null)
            {
               RNotice.show(LayerManager.getBaseTop(), "小屋还在修复中，敬请期待！");
               return;
            }
            loader.loadHouse(SocketClient.instance.myUserName);
         });
      }

      private static function showPanel(service:String):void
      {
         ServiceContainer.instance.tryGetService(service, function(svc:IService, o:Object):void
         {
            var p:Object = svc;
            if (p != null && p.hasOwnProperty("showPanel"))
            {
               try { p.showPanel(); return; } catch (e:Error) { RLog.error("control " + service, e); }
            }
            RNotice.show(LayerManager.getBaseTop(), "这个功能还在修复中哦！");
         });
      }

      /** A point of the stage where `d` draws (and so takes a click), near the middle of what shows. */
      private static function clickPoint(d:DisplayObject):String
      {
         var r:Rectangle = d.getBounds(d.stage).intersection(new Rectangle(0, 0, 960, 560));
         if (r.isEmpty()) return null;
         var hits:Array = [];
         var sx:Number = 0, sy:Number = 0;
         // Coarse first, then finer for something small in large bounds.
         for each (var step:Number in [Math.max(4, Math.sqrt(r.width * r.height / 4000)), 3])
         {
            for (var y:Number = r.y + step / 2; y < r.bottom; y += step)
            {
               for (var x:Number = r.x + step / 2; x < r.right; x += step)
               {
                  if (d.hitTestPoint(x, y, true))
                  {
                     hits.push(new Point(x, y));
                     sx += x;
                     sy += y;
                  }
               }
            }
            if (hits.length > 0) break;
         }
         if (hits.length == 0) return null;
         var mid:Point = new Point(sx / hits.length, sy / hits.length);
         var best:Point = hits[0];
         for each (var h:Point in hits) if (Point.distance(h, mid) < Point.distance(best, mid)) best = h;
         return int(best.x) + "," + int(best.y);
      }

      private static function findNamed(c:DisplayObjectContainer, name:String, hidden:Boolean = false):DisplayObject
      {
         var queue:Array = [c];
         while (queue.length > 0)
         {
            var d:DisplayObjectContainer = queue.shift();
            for (var i:int = 0; i < d.numChildren; i++)
            {
               var o:DisplayObject = d.getChildAt(i);
               if (o.name == name && (hidden || o.visible)) return o;
               if (o is DisplayObjectContainer && (hidden || o.visible)) queue.push(o);
            }
         }
         return null;
      }

      /** Test hook for the automated scene walk-through (tests/e2e): not in the 2013 game. */
      private function installDebugHook():void
      {
         if (!ExternalInterface.available) return;
         try
         {
            ExternalInterface.addCallback("revival", function(cmd:String, arg:String = null):String
            {
               var sm:SceneManager = SceneManager.getInstance();
               switch (cmd)
               {
                  case "goto": sm.loadScene(arg); return "ok";
                  case "map": openMap(); return "ok";
                  case "home": goHome(); return "ok";
                  case "scene": return sm.loadedSceneInfo ? sm.loadedSceneInfo.sceneName : "";
                  case "busy": return sm.isLoading ? "1" : "0";
                  case "top":
                     // The names of what lies on the top layer (revivalComic, panels …).
                     var tl:DisplayObjectContainer = LayerManager.getBaseTop();
                     var names:Array = [];
                     for (var ti:int = 0; tl && ti < tl.numChildren; ti++) names.push(tl.getChildAt(ti).name + ":" + getQualifiedClassName(tl.getChildAt(ti)));
                     return names.join(",");
                  case "layers": return describe(LayerManager.stage, int(arg) || 3);
                  case "pet": showPanel("NewPetPackage"); return "ok";
                  case "panel": showPanel(arg); return "ok";
                  case "fight": PetClient2.instance.startPKWithRobot(int(arg)); return "ok";
                  case "give":
                     // Only answered by a server started with dev commands (web/?dev=1).
                     SocketClient.instance.sendXtMessage("PocketMonsterExtension", "revival_give", {mi: int(arg), qt: 5});
                     return "ok";
                  case "wild":
                     // The wild 亚比 of the scene as wildpet<i>:<race>@x,y h<height>.
                     var wl:DisplayObjectContainer = sm.loadedSceneInfo && sm.loadedSceneInfo.scene ? sm.loadedSceneInfo.scene.playerLayer : null;
                     var ws:Array = [];
                     for (var wi:int = 0; wl && wi < wl.numChildren; wi++)
                     {
                        var wd:Object = wl.getChildAt(wi);
                        if (wd.name.indexOf("wildpet") == 0) ws.push(wd.name + ":" + (wd.hasOwnProperty("race") ? wd.race : "?") + "@" + int(wd.x) + "," + int(wd.y) + "h" + int(wd.height));
                     }
                     return ws.join(",");
                  case "clickwild":
                     // Click the n-th wild 亚比 of the scene (pet/wildpetservice names them wildpet0…).
                     var layer:DisplayObjectContainer = sm.loadedSceneInfo && sm.loadedSceneInfo.scene ? sm.loadedSceneInfo.scene.playerLayer : null;
                     var pet:DisplayObject = layer ? layer.getChildByName("wildpet" + int(arg)) : null;
                     if (pet == null) return "none";
                     pet.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
                     return int(pet.x) + "," + int(pet.y);
                  case "say":
                     ServiceContainer.instance.tryGetService("SceneTalkService", function(svc:IService, o:Object):void { Object(svc).say(arg); });
                     return "ok";
                  case "smile":
                     ServiceContainer.instance.tryGetService("SceneTalkService", function(svc:IService, o:Object):void { Object(svc).smile(int(arg)); });
                     return "ok";
                  case "act":
                     ActionHelper.Instance.doAction(arg, PlayerManager.getInstance().myPlayer);
                     return "ok";
                  case "talk":
                     // The open NPC conversation, or with a number: pick that choice (tests/e2e).
                     try
                     {
                        var panel:Object = getDefinitionByName("mmo.tasknpc.NpcTalkPanel");
                        return arg == null || arg == "" ? String(panel.debugText()) : String(panel.debugChoose(int(arg)));
                     }
                     catch (err:Error) { return "error " + err.message; }
                     return "";
                  case "npc":
                     try { return String(getDefinitionByName("mmo.tasknpc.TaskNpcService").instance.debugClick(int(arg))); }
                     catch (err2:Error) { return "error " + err2.message; }
                     return "";
                  case "tasktest":
                     // Only answered by a server started with dev commands (web/?dev=1).
                     SocketClient.instance.sendXtMessage("TaskExtension", "revival_task", {ti: int(arg)});
                     return "ok";
                  case "action":
                     // A task action, as a conversation choice or a mini game sends it (tests/e2e).
                     TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_TASK_ACTION, {action: arg}));
                     return "ok";
                  case "where":
                  case "origin":
                     // Where a shown display object of that name is, in the scene or else
                     // anywhere on the stage (tests/e2e): "where" the middle of what it
                     // draws, "origin" its registration point (hidden ones too).
                     var root:DisplayObjectContainer = sm.loadedSceneInfo ? sm.loadedSceneInfo.scene : null;
                     var hidden:Boolean = cmd == "origin";
                     var found:DisplayObject = root ? findNamed(root, arg, hidden) : null;
                     if (found == null && LayerManager.stage) found = findNamed(LayerManager.stage, arg, hidden);
                     if (found == null || found.stage == null) return "none";
                     if (hidden)
                     {
                        var o:Point = found.localToGlobal(new Point(0, 0));
                        return int(o.x) + "," + int(o.y);
                     }
                     return String(clickPoint(found) || "none");
                  case "bounds":
                     // name: visible, bounds on the stage, parent chain (tests/e2e).
                     var bo:DisplayObject = LayerManager.stage ? findNamed(LayerManager.stage, arg, true) : null;
                     if (bo == null) return "none";
                     var br:Rectangle = bo.stage ? bo.getBounds(bo.stage) : null;
                     var chain:Array = [];
                     for (var bp:DisplayObject = bo; bp != null && bp != bo.stage; bp = bp.parent) chain.push(bp.name + (bp.visible ? "" : "(hidden)"));
                     return (br ? int(br.x) + "," + int(br.y) + " " + int(br.width) + "x" + int(br.height) : "off stage") + " " + chain.join("<");
                  case "addpet":
                     // A 亚比 of that race, Lv 15, through addPM (1201), the command tasks give 亚比 with (tests/e2e).
                     SocketClient.instance.sendXtMessage("PocketMonsterExtension", "1201", {raceId: int(arg), level: 15, type: 0});
                     return "ok";
                  case "tasks":
                     var ts:Object = ServiceContainer.getService("TaskService");
                     return ts ? String(ts.getDoingTaskIds()) + " steps " + [135, 140, 150].concat(ts.getDoingTaskIds()).map(function(t:int, ...r):String { return t + ":" + ts.getTaskDoingStep(t); }).join(",") : "none";
                  case "bar":
                     // Press a control bar button by name (phrase face action history card …).
                     onButton(arg);
                     return bar.popupShown ? getQualifiedClassName(bar.popupShown) : "ok";
                  case "follow":
                     // Let my first 亚比 follow me (or, with arg "back", send it back).
                     ServiceContainer.instance.tryGetService("PetFollowService", function(svc:IService, o:Object):void
                     {
                        var data:Object = ServiceContainer.getService("PetDataService");
                        var list:Array = data ? data.getMyPets() : [];
                        if (arg == "back") Object(svc).setBackPackage();
                        else if (list.length > 0) Object(svc).setFollow(list[0].id, list[0].raceId);
                     });
                     return "ok";
               }
               return "unknown";
            });
         }
         catch (e:Error)
         {
            RLog.error("control debug hook", e);
         }
      }

      private static function describe(d:DisplayObject, depth:int, indent:String = ""):String
      {
         if (d == null) return "";
         var s:String = indent + getQualifiedClassName(d) + " '" + d.name + "' vis=" + d.visible + " a=" + d.alpha
            + " " + int(d.x) + "," + int(d.y) + " " + int(d.width) + "x" + int(d.height) + "\n";
         var c:DisplayObjectContainer = d as DisplayObjectContainer;
         if (c != null && depth > 0)
         {
            try
            {
               for (var i:int = 0; i < c.numChildren; i++) s += describe(c.getChildAt(i), depth - 1, indent + "  ");
            }
            catch (e:Error) {}
         }
         return s;
      }

      public function change2commonMode():Boolean
      {
         fbMode = false;
         if (bar) bar.setMode("common");
         return true;
      }

      public function change2fbMode(leaveButton:InteractiveObject = null, mapButton:InteractiveObject = null):Boolean
      {
         fbMode = true;
         _fbLeave = leaveButton;
         _fbMap = mapButton;
         if (bar) bar.setMode("fb");
         return true;
      }

      public function changeToSpaceTimeMode(callback:Function = null, name:String = null):Boolean
      {
         if (bar) bar.setMode("spacetime");
         return true;
      }

      public function hide():void
      {
         if (bar) bar.visible = false;
      }

      public function show():void
      {
         if (bar) bar.visible = true;
      }

      public function get commonMapButton():InteractiveObject
      {
         return bar ? bar.mapButton : null;
      }

      public function get fbLeaveButton():InteractiveObject
      {
         return _fbLeave;
      }

      public function get fbMapButton():InteractiveObject
      {
         return _fbMap ? _fbMap : (bar ? bar.mapButton : null);
      }
   }
}
