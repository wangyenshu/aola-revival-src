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
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
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
    * module, mmo.tasknpcdefine.NpcNames / NpcDefaultTalk). Task NPCs (type 2)
    * appear with the task engine; until then only scene NPCs (type 0) stand.
    */
   public class TaskNpcService extends Sprite implements ITaskNpcService
   {
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

      public static function defaultTalk(id:int):Array
      {
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
         var list:Array = SceneNpcData.SCENES[info.sceneName] as Array;
         if (list == null) return;
         for each (var row:Array in list)
         {
            if (row[4] != 0) continue; // task NPCs come with their tasks
            addNpcToScene(row[0], row[1], -1, row[2], row[3]);
         }
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_INITED_NPC, {sceneName: info.sceneName}));
      }

      public function addNpcToScene(npcId:int, viewId:int, taskId:int, x:int, y:int):void
      {
         removeNpcFromScene(npcId);
         var npc:Npc = new Npc(npcId, viewId, x, y, onNpcClick);
         npcs[npcId] = npc;
         npc.load();
         if (taskTalks[npcId] != null) npc.setTaskMark(true);
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
         showNpcPanel(npc.id, -1, null);
      }

      // ---------------------------------------------------------------- task conversations

      private var taskTalks:Object = {};
      private var taskTalkConfig:Object = {};

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

      /** Conversations a task script names "npcId_taskId_from", for showNpcPanel (the later TaskNpcPanelConfig). */
      public function setTaskNpcPanelConfig(config:Object):void
      {
         for (var k:String in config) taskTalkConfig[k] = config[k];
      }

      /** The NPC's own panel: a greeting, plus the choices scenes added with addNpcInteraction. */
      public function showNpcPanel(npcId:int, taskId:int, from:String):void
      {
         var named:XML = taskTalkConfig[npcId + "_" + taskId + "_" + from] as XML;
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
         NpcTalkPanel.show(xml, npcId);
      }

      public function showNpcPanelFreely(name:String, npcId:int, iconId:int = 1):void
      {
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
