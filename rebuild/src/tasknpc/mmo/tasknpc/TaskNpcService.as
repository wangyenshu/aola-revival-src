package mmo.tasknpc
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.task.ext.TaskNpcPanelConfig;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.revival.RLog;

   /**
    * REBUILT task/tasknpc (mmo.tasknpc.TaskNpcService, ITaskNpcService).
    *
    * Puts the scene NPCs of each room into the scene (artwork: the original
    * tasknpc/npc<id>.swf files, class mmo.tasknpc.Npc<id>_<view>), shows their
    * names and greeting bubbles, and opens the NPC conversation panel: on a
    * click, for the conversations scenes ask for by name
    * (showNpcPanelFreely), and for the XML ones they build themselves
    * (showNpcPanelFreelyByXml). Choices send TaskEvent.ON_TASK_ACTION as the
    * 2013 panel did, which is how scenes react to them.
    *
    * Data: SceneNpcData and FreeTalkData (tools/gen_npc_data.py, from the later
    * module); names and greetings from task/tasknpcdefine (the later data
    * module, mmo.tasknpcdefine.NpcNames / NpcDefaultTalk); the conversations
    * of the 2012 story quests in TaskTalkData (tools/gen_tasks.py, from the
    * later module's NpcPanelConfig): "npc_step_scene" while that step is
    * being done, and start talks "npc_task_scene" while that task can start.
    * As in the later TaskNpcManager, a click on an NPC opens its task talk
    * when it has one, and task NPCs (type 2) stand in their scene only while
    * they have something to say for a task.
    */
   public class TaskNpcService extends Sprite implements ITaskNpcService
   {
      /**
       * The namespace of the later ITaskNpcService's methods. Task scripts
       * compiled against the later interface call setTaskNpcPanelConfig and
       * updateNpc in it (callproperty QName(Namespace("mmo.interfaces.task:
       * ITaskNpcService"), …)); the 2013 interface this class implements
       * does not have them, so they are defined in it here by hand.
       */
      namespace later_itf = "mmo.interfaces.task:ITaskNpcService";

      private static var _instance:TaskNpcService;
      private var npcs:Object = {};
      private var interactions:Object = {};
      private var bubbleTimer:Timer;
      private var defineReady:Boolean;

      public function TaskNpcService()
      {
         super();
         _instance = this;
      }

      public static function get instance():TaskNpcService
      {
         return _instance;
      }

      public function init():void
      {
         try { TaskTalkData.fill(taskTalkConfig, starterTalkConfig); } catch (e:Error) { RLog.error("tasknpc: task talk", e); }
         for each (var ev:String in [TaskEvent.ON_GET_TASKS, TaskEvent.ON_USER_TASK_ADD, TaskEvent.ON_USER_TASK_FINISH, TaskEvent.ON_USER_TASK_DROP])
            TaskEventDispatcher.instance.addEventListener(ev, onTasksChanged);
         SimpleCustomLoader.loadSingleResource("task/tasknpcdefine", "mmo.tasknpcdefine.TaskNpcDefine", LoadingSpriteType.NONE, "",
            function(o:Object):void
            {
               defineReady = true;
               if (SceneManager.getInstance().loadedSceneInfo) initNpc();
            });
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED, onSceneInited);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE, onSceneUnload);
         bubbleTimer = new Timer(7000);
         bubbleTimer.addEventListener(TimerEvent.TIMER, onBubbleTick);
         bubbleTimer.start();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      private function onSceneInited(e:SceneManagerEvent):void
      {
         initNpc();
      }

      private function onSceneUnload(e:SceneManagerEvent):void
      {
         taskTalks = {};
         clearNpcs();
         NpcTalkPanel.closeCurrent();
      }

      // ---------------------------------------------------------------- names

      public static function npcName(id:int):String
      {
         try
         {
            var c:Object = getDefinitionByName("mmo.tasknpcdefine.NpcNames");
            var n:* = c.Config[id];
            if (n != null) return String(n);
         }
         catch (e:Error) {}
         return "";
      }

      /**
       * RECONSTRUCTED greetings for NPCs whose later default talk speaks of
       * later stories (维克's 礼箱 and 亚特兰蒂斯): lines of the era's own
       * conversations instead (维克's is his reply in the delivery talk
       * carrierBearLearnSkillTalk_13).
       */
      private static const ERA_TALK:Object = {
         13: ["嗯，最近收到的挑战信越来越多啦！不过难不倒我异星使者维克的。"]
      };

      /**
       * The NPCs of the era npcchallenge/npcchallengeservice (ChallengeConfig):
       * id -> scene. Their panel offers the challenge (TaskEvent action
       * "npcchallenge<id>", which that service answers with npcChallenge_talk).
       * The 2013 choice text is lost (RECONSTRUCTED).
       */
      private static const CHALLENGE:Object = {
         13: "maintown1", 35: "starland", 145: "bluesquare", 14: "helloschool", 3: "toolshop",
         26: "fastclub", 142: "bluesquare", 32: "furnitureshop", 31: "clothesshop", 172: "bluesquare", 312: "temple6"
      };

      public static function defaultTalk(id:int):Array
      {
         if (ERA_TALK[id] != null) return ERA_TALK[id] as Array;
         try
         {
            var c:Object = getDefinitionByName("mmo.tasknpcdefine.NpcDefaultTalk");
            var a:Array = c.DefaultConfig[id] as Array;
            if (a != null && a.length > 0) return a;
         }
         catch (e:Error) {}
         return null;
      }

      // ---------------------------------------------------------------- NPCs in the scene

      public function initNpc():void
      {
         clearNpcs();
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info == null) return;
         // Scenes without NPCs of their own still announce ON_INITED_NPC: task scripts wait for it.
         var list:Array = (SceneNpcData.SCENES[info.sceneName] as Array) || [];
         for each (var row:Array in list)
         {
            // Task NPCs come with their tasks; the hosts of their rooms are always there.
            if (row[4] != 0 && !isResident(row[0], info.sceneName) && taskTalksOf(row[0], info.sceneName).length == 0) continue;
            addNpcToScene(row[0], row[1], -1, row[2], row[3]);
         }
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_INITED_NPC, {sceneName: info.sceneName}));
      }

      /** Tasks changed: task NPCs come and go, marks follow. */
      private function onTasksChanged(e:TaskEvent):void
      {
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         if (info == null || SceneManager.getInstance().isLoading) return;
         for each (var row:Array in (SceneNpcData.SCENES[info.sceneName] as Array) || [])
         {
            if (row[4] == 0 || isResident(row[0], info.sceneName)) continue;
            var has:Boolean = taskTalksOf(row[0], info.sceneName).length > 0;
            if (has && npcs[row[0]] == null) addNpcToScene(row[0], row[1], -1, row[2], row[3]);
            else if (!has && npcs[row[0]] != null && taskTalks[row[0]] == null) removeNpcFromScene(row[0]);
         }
         for (var k:String in npcs) Npc(npcs[k]).setTaskMark(hasTaskTalk(int(k)));
      }

      /**
       * NPCs the later scene table marks as task NPCs that were the hosts of
       * their rooms in 2012 and stood there whatever the tasks: 贝鲁特博士 (11)
       * in the 亚比研究中心 (his era default talk is in ERA_TALK / NpcDefaultTalk).
       */
      private static const RESIDENTS:Object = {"yabistudy": [11], "yabistudycopy": [11]};

      private static function isResident(npcId:int, scene:String):Boolean
      {
         var a:Array = RESIDENTS[scene] as Array;
         return a != null && a.indexOf(npcId) >= 0;
      }

      public function addNpcToScene(npcId:int, viewId:int, taskId:int, x:int, y:int):void
      {
         removeNpcFromScene(npcId);
         var npc:Npc = new Npc(npcId, viewId, x, y, onNpcClick);
         npcs[npcId] = npc;
         npc.load();
         if (hasTaskTalk(npcId)) npc.setTaskMark(true);
      }

      public function addSeveralNpcToScene(list:Array):void
      {
         for each (var o:Object in list)
         {
            if (o is Array) addNpcToScene(o[0], o[1], -1, o[2], o[3]);
            else if (o != null && o.hasOwnProperty("npcId")) addNpcToScene(o.npcId, o.viewId, -1, o.x, o.y);
            else if (o is int || o is Number) addKnownNpc(int(o));
         }
      }

      private function addKnownNpc(id:int):void
      {
         for each (var list:Array in SceneNpcData.SCENES)
         {
            for each (var row:Array in list)
            {
               if (row[0] == id)
               {
                  addNpcToScene(row[0], row[1], -1, row[2], row[3]);
                  return;
               }
            }
         }
      }

      public function removeSeveralNpcToScene(list:Array):void
      {
         for each (var o:* in list) removeNpcFromScene(o is Object && o.hasOwnProperty("npcId") ? o.npcId : int(o));
      }

      public function removeNpcFromScene(npcId:int):void
      {
         var npc:Npc = npcs[npcId] as Npc;
         if (npc == null) return;
         npc.dispose();
         delete npcs[npcId];
      }

      public function getNpcView(npcId:int):DisplayObject
      {
         var npc:Npc = npcs[npcId] as Npc;
         return npc ? npc.view : null;
      }

      public function changeNpcView(npcId:int, viewId:int, at:Point = null):void
      {
         var npc:Npc = npcs[npcId] as Npc;
         if (npc == null) return;
         var x:int = at ? at.x : npc.x;
         var y:int = at ? at.y : npc.y;
         addNpcToScene(npcId, viewId, -1, x, y);
      }

      public function getSceneNpcInfo(scene:String):Array
      {
         var out:Array = [];
         for each (var row:Array in (SceneNpcData.SCENES[scene] as Array) || [])
         {
            out.push({npcId: row[0], viewId: row[1], x: row[2], y: row[3], type: row[4]});
         }
         return out;
      }

      private function clearNpcs():void
      {
         for (var k:String in npcs) Npc(npcs[k]).dispose();
         npcs = {};
      }

      private function onBubbleTick(e:TimerEvent):void
      {
         var list:Array = [];
         for (var k:String in npcs)
         {
            var n:Npc = npcs[k] as Npc;
            if (n.view != null && defaultTalk(n.id) != null) list.push(n);
         }
         if (list.length == 0 || NpcTalkPanel.isOpen) return;
         var pick:Npc = list[int(Math.random() * list.length)];
         var lines:Array = defaultTalk(pick.id);
         pick.say(lines[int(Math.random() * lines.length)]);
      }

      // ---------------------------------------------------------------- conversations

      /** Test hook (tests/e2e, the control's "npc" command): click an NPC of the scene. */
      public function debugClick(npcId:int):String
      {
         var npc:Npc = npcs[npcId] as Npc;
         if (npc == null) return "no npc " + npcId;
         onNpcClick(npc);
         return "ok";
      }

      private function onNpcClick(npc:Npc):void
      {
         var talk:XML = taskTalks[npc.id] as XML;
         if (talk != null)
         {
            NpcTalkPanel.show(talk, npc.id);
            return;
         }
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         var list:Array = info ? taskTalksOf(npc.id, info.sceneName) : [];
         if (list.length == 1)
         {
            NpcTalkPanel.show(list[0].xml, npc.id);
            return;
         }
         if (list.length > 1)
         {
            // Several tasks with this NPC: name them, as the later panel does.
            var lines:Array = defaultTalk(npc.id);
            var menu:XML = <config><context/></config>;
            menu.context.@npcId = npc.id;
            menu.context.@str = lines ? lines[0] : "你好，小奥拉！";
            for each (var o:Object in list)
            {
               var c:XML = <choice/>;
               c.@str = "【任务】" + o.name;
               for each (var ctx:XML in XML(o.xml).context) c.appendChild(ctx.copy());
               menu.context.appendChild(c);
            }
            NpcTalkPanel.show(menu, npc.id);
            return;
         }
         showNpcPanel(npc.id, -1, null);
      }

      // ---------------------------------------------------------------- task conversations

      private var taskTalks:Object = {};
      private var taskTalkConfig:Object = {};
      private var starterTalkConfig:Object = {};
      private var freeTalkConfig:Object = {};

      private static function taskService():ITaskService
      {
         return ServiceContainer.getService(ITaskService) as ITaskService;
      }

      /**
       * The task talks of an NPC in a scene (the later NpcPanelConfig.
       * getDoingTaskTalkXmlByNpc): for every task being done, the talk of its
       * current step; for every task that can start, its start talk.
       */
      private function taskTalksOf(npcId:int, scene:String):Array
      {
         var out:Array = [];
         var ts:ITaskService = taskService();
         if (ts == null || (Object(ts).hasOwnProperty("ready") && !Object(ts).ready)) return out;
         for each (var id:int in ts.getDoingTaskIds())
         {
            var step:int = ts.getTaskDoingStep(id);
            var x:XML = taskTalkConfig[npcId + "_" + step + "_" + scene] as XML;
            if (x != null) out.push({task: id, xml: x, name: nameOf(ts, id)});
         }
         for (var k:String in starterTalkConfig)
         {
            var p:Array = k.split("_");
            if (p.length != 3 || int(p[0]) != npcId || p[2] != scene || !ts.isTaskCanStart(int(p[1]))) continue;
            out.push({task: int(p[1]), xml: starterTalkConfig[k], name: nameOf(ts, int(p[1]))});
         }
         return out;
      }

      private static function nameOf(ts:ITaskService, id:int):String
      {
         var s:Object = ts.getTaskStarter(id);
         return s ? String(s.taskName) : "";
      }

      private function hasTaskTalk(npcId:int):Boolean
      {
         if (taskTalks[npcId] != null) return true;
         var info:Object = SceneManager.getInstance().loadedSceneInfo;
         return info != null && taskTalksOf(npcId, info.sceneName).length > 0;
      }

      /**
       * REBUILT helper for the task scripts (not in the 2013 interface): while
       * a step is being done, a click on this NPC opens the step's
       * conversation instead of the greeting. Cleared with the scene.
       */
      public function setTaskTalk(npcId:int, xml:XML):void
      {
         if (xml == null) delete taskTalks[npcId];
         else taskTalks[npcId] = xml;
         var npc:Npc = npcs[npcId] as Npc;
         if (npc != null) npc.setTaskMark(xml != null);
      }

      /**
       * Conversations a task script names "npcId_taskId_from", for showNpcPanel:
       * a map of them, or a later TaskNpcPanelConfig (its task talks, start
       * talks and free talks, merged as the later NpcPanelConfig does).
       */
      public function setTaskNpcPanelConfig(config:Object):void
      {
         var k:String;
         var c:TaskNpcPanelConfig = config as TaskNpcPanelConfig;
         if (c == null)
         {
            for (k in config) taskTalkConfig[k] = config[k];
            return;
         }
         for (k in c.npcFreeTaskTalkConfig) freeTalkConfig[k] = c.npcFreeTaskTalkConfig[k];
         for (k in c.npcTaskTalkConfig) taskTalkConfig[k] = c.npcTaskTalkConfig[k];
         for (k in c.npcStarterTalkConfig) starterTalkConfig[k] = c.npcStarterTalkConfig[k];
      }

      /** The later updateNpc: task NPCs of the scene come and go, marks follow (TaskNpcManager.freshNpc). */
      public function updateNpc():void
      {
         onTasksChanged(null);
      }

      /** LATER ITaskNpcService.setTaskNpcPanelConfig (see later_itf). */
      later_itf function setTaskNpcPanelConfig(config:TaskNpcPanelConfig):void
      {
         this.setTaskNpcPanelConfig(config);
      }

      /** LATER ITaskNpcService.updateNpc (see later_itf). */
      later_itf function updateNpc():void
      {
         this.updateNpc();
      }

      /** The NPC's own panel: a greeting, plus the choices scenes added with addNpcInteraction. */
      public function showNpcPanel(npcId:int, taskId:int, from:String):void
      {
         var key:String = npcId + "_" + taskId + "_" + from;
         var named:XML = (taskTalkConfig[key] || starterTalkConfig[key]) as XML;
         if (named == null && taskId > 0)
         {
            // REBUILT fallback: a 2012 script may name a talk the later tables
            // keep under another NPC of the same task and place.
            for each (var conf:Object in [taskTalkConfig, starterTalkConfig])
            {
               for (var k:String in conf)
               {
                  var p:Array = k.split("_");
                  if (p.length == 3 && int(p[1]) == taskId && p[2] == from)
                  {
                     named = conf[k] as XML;
                     npcId = int(p[0]);
                     break;
                  }
               }
               if (named != null) break;
            }
         }
         if (named != null)
         {
            NpcTalkPanel.show(named, npcId);
            return;
         }
         var lines:Array = defaultTalk(npcId);
         var text:String = lines ? lines[int(Math.random() * lines.length)] : "你好，小奥拉！";
         var xml:XML = <config><context/></config>;
         xml.context.@npcId = npcId;
         xml.context.@str = text;
         var extra:Array = interactions[npcId] as Array;
         for each (var it:Object in extra || [])
         {
            var c:XML = <choice/>;
            c.@str = it.text;
            c.@action = it.action;
            xml.context.appendChild(c);
         }
         var here:Object = SceneManager.getInstance().loadedSceneInfo;
         if (CHALLENGE[npcId] != null && here != null && here.sceneName == CHALLENGE[npcId])
         {
            var ch:XML = <choice str="我要和你进行亚比对战！"/>;
            ch.@action = "npcchallenge" + npcId;
            xml.context.appendChild(ch);
         }
         NpcTalkPanel.show(xml, npcId);
      }

      public function showNpcPanelFreely(name:String, npcId:int, iconId:int = 1):void
      {
         if (freeTalkConfig[name] is XML)
         {
            NpcTalkPanel.show(freeTalkConfig[name] as XML, npcId, iconId);
            return;
         }
         var hit:XMLList = FreeTalkData.TALKS.t.(@k == name);
         if (hit.length() == 0)
         {
            RLog.log("tasknpc: no conversation named " + name);
            showNpcPanel(npcId, -1, name);
            return;
         }
         NpcTalkPanel.show(XML(hit[0].config[0]), npcId, iconId);
      }

      public function showNpcPanelFreelyByXml(xml:XML, npcId:int, iconId:int = 1):void
      {
         NpcTalkPanel.show(xml, npcId, iconId);
      }

      public function showHelloPanel(id:int):void
      {
         showNpcPanel(1, -1, "hello");
      }

      public function showSystemPanel(o:*):void
      {
         if (o is XML) NpcTalkPanel.show(o as XML, 0);
         else if (o is String) NpcTalkPanel.show(XML("<config><context str=\"" + String(o).replace(/"/g, "&quot;") + "\"/></config>"), 0);
      }

      public function addNpcInteraction(npcId:int, text:String, action:String):void
      {
         var list:Array = interactions[npcId] as Array;
         if (list == null) interactions[npcId] = list = [];
         for each (var it:Object in list) if (it.action == action) return;
         list.push({text: text, action: action});
      }

      public function removeNpcInteraction(npcId:int, action:String):void
      {
         var list:Array = interactions[npcId] as Array;
         if (list == null) return;
         for (var i:int = list.length - 1; i >= 0; i--) if (list[i].action == action) list.splice(i, 1);
      }
   }
}
