package mmo.play.scene
{
   import flash.utils.setTimeout;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.media.SoundMixer;
   import flash.events.EventDispatcher;
   import flash.geom.Point;
   import mmo.config.ConfigReader;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.loader.layer.LayerManager;
   import mmo.play.player.PlayerManager;
   import mmo.socketserver.data.Room;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT. Loads a scene SWF named in config.xml's room map, joins its room
    * through the original 2013 SocketClient, places the players and calls the
    * scene's onJoinRoom(). API as used by surviving scenes and modules:
    * getInstance(), loadScene(name), loadDefaultScene(), loadPreviousScene(),
    * getLastRoomName(), getPreviousRoomName(), loadedSceneInfo, and the
    * SceneManagerEvent notifications.
    */
   public class SceneManager extends EventDispatcher
   {
      public static const DEFAULT_SCENE:String = "starland";
      /** Tried in order when the first scene of a session cannot be entered. */
      public static const FALLBACK_SCENES:Array = ["starland", "yabiunion", "teambattleoutside"];

      private static var _instance:SceneManager;

      public var loadedSceneInfo:SceneInfo;

      /** LATER helper: the name of the scene the player is in ("" while none is). */
      public function getCurSceneName():String
      {
         return loadedSceneInfo != null ? loadedSceneInfo.sceneName : "";
      }
      private var loadingInfo:SceneInfo;
      private var history:Array = [];
      private var busy:Boolean;
      private var fileArrived:Boolean;
      private var loadingHooks:Object = {};

      public static function getInstance():SceneManager
      {
         if (_instance == null)
         {
            _instance = new SceneManager();
         }
         return _instance;
      }

      private var _suspended:Boolean;

      /** True while the game is paused for a full-screen panel or mini game; the avatar renderer checks it. */
      public function get isSuspend():Boolean
      {
         return _suspended;
      }

      public function set isSuspend(v:Boolean):void
      {
         if (v == _suspended) return;
         _suspended = v;
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.SUSPEND_STATE_CHANGED, {isSuspend: v}));
      }

      public function get isLoading():Boolean
      {
         return busy;
      }

      /** The mini game being played: {sceneName, swf, ext, doc, view}; null outside games. */
      public var loadedGameInfo:Object;
      private var gameLayer:Sprite;

      /**
       * REBUILT. A mini game: a room of config.xml with game="1" (GameTable
       * names them; IGameManager.loadGame) whose SWF has a DocGameBase
       * document class. Its game view (DocGameBase.game, or the document
       * itself when that is null, as in game/ropedancer) covers the screen on
       * the apps layer, under the dialogs it opens; unloadGame() takes it away
       * and the player is back in the scene (entered again, SCENE_INITED, as
       * after leaving a 2013 game room; games wait for that).
       */
      public function loadGame(name:String, show:Boolean = true, ext:* = null):void
      {
         if (busy || loadedGameInfo != null) return;
         var cfg:ConfigReader = ConfigReader.instance;
         var swf:String = cfg.getSceneSwf(name);
         if (swf == null || swf == "")
         {
            RLog.log("scene: no game named " + name);
            RNotice.show(LayerManager.getBaseScene().stage, "这个小游戏还没有修复好哦！");
            return;
         }
         var e:SceneManagerEvent = new SceneManagerEvent(SceneManagerEvent.ON_LOADING_SCENE, {sceneName: name, game: true});
         dispatchEvent(e);
         if (e.params.cancel) return;
         busy = true;
         var info:Object = {sceneName: name, swf: swf, ext: ext};
         var arrived:Boolean = false;
         var desc:String = cfg.getSceneDescription(name);
         RLog.log("scene: loadGame " + name + " (" + swf + ")");
         SimpleCustomLoader.loadSingleResource(swf, null, LoadingSpriteType.FULL_SCREEN, "正在打开" + (desc || "小游戏") + "……", function(content:Object):void
         {
            arrived = true;
            busy = false;
            try
            {
               var doc:DocGameBase = content as DocGameBase;
               if (doc == null && content != null && content.hasOwnProperty("content")) doc = content["content"] as DocGameBase;
               var view:DisplayObject = doc != null ? doc.game : null;
               if (view == null) view = (doc != null ? doc : content) as DisplayObject;
               if (view == null) throw new Error("not a game document");
               info.doc = doc;
               info.view = view;
               loadedGameInfo = info;
               gameLayer = new Sprite();
               gameLayer.name = "gameLayer";
               gameLayer.graphics.beginFill(0x000000);
               gameLayer.graphics.drawRect(0, 0, 960, 560);
               gameLayer.graphics.endFill();
               gameLayer.addChild(view);
               LayerManager.getBaseApp().addChild(gameLayer);
               isSuspend = true;
               dispatchEvent(new SceneManagerEvent(SceneManagerEvent.GAME_INITED, {gameInfo: info, sceneName: name}));
            }
            catch (err:Error)
            {
               RLog.error("scene: game " + name, err);
               loadedGameInfo = null;
               if (gameLayer && gameLayer.parent) gameLayer.parent.removeChild(gameLayer);
               gameLayer = null;
               RNotice.show(LayerManager.getBaseScene().stage, "这个小游戏打不开了。");
            }
         }, this, function():void
         {
            setTimeout(function():void
            {
               if (!arrived && busy)
               {
                  busy = false;
                  RNotice.show(LayerManager.getBaseScene().stage, "这个小游戏的文件找不到了。");
               }
            }, 0);
         });
      }

      public function unloadGame():void
      {
         var info:Object = loadedGameInfo;
         loadedGameInfo = null;
         if (gameLayer != null && gameLayer.parent != null) gameLayer.parent.removeChild(gameLayer);
         gameLayer = null;
         if (info != null)
         {
            try { if (info.view is MovieClip) MovieClip(info.view).stop(); } catch (e1:Error) {}
            SoundMixer.stopAll();
            isSuspend = false;
         }
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.UNLOAD_GAME, {gameInfo: info}));
         if (info != null && loadedSceneInfo != null)
         {
            var back:String = loadedSceneInfo.sceneName;
            setTimeout(function():void { loadScene(back, "default", true); }, 0);
         }
      }

      /** Instance (副本) scenes: entered like any scene, keyed by their scene name. */
      private var _nextFB:Object;

      /** Instance (副本) scenes: loadFB(sceneName, fbName[, description]); loadedSceneInfo is then an FBSceneInfo. */
      public function loadFB(sceneName:String, fbName:String, desc:String = "", teamKey:String = "", locationKey:* = "default", face:* = "ld", ext:* = null):void
      {
         _nextFB = {fbName: fbName, teamKey: teamKey, desc: desc};
         loadScene(sceneName, String(locationKey));
      }

      public function loadTempScene(sceneName:String, name:String, desc:String = "", b:String = "", locationKey:* = "default", face:String = "ld", ext:* = null):void
      {
         loadScene(sceneName, String(locationKey));
      }

      public function getLastRoomName():String
      {
         return loadedSceneInfo ? loadedSceneInfo.sceneName : null;
      }

      public function getPreviousRoomName():String
      {
         return history.length > 1 ? history[history.length - 2] : null;
      }

      /** The last scene outside the homes (where leaving a home goes back to). */
      public function get lastOutdoorScene():String
      {
         return history.length > 0 ? history[history.length - 1] : DEFAULT_SCENE;
      }

      public function loadDefaultScene():void
      {
         loadScene(DEFAULT_SCENE);
      }

      public function loadPreviousScene():void
      {
         var prev:String = getPreviousRoomName();
         loadScene(prev ? prev : DEFAULT_SCENE, getLastRoomName() ? "from" + getLastRoomName() : "default");
      }

      /**
       * Newbie copies of scenes that only survive as later re-drawings
       * (maintown1copy, maintown2copy, yabistudycopy: 2014-ish art); the era
       * scene they copy stands in for each (REBUILT choice).
       */
      public static const STAND_INS:Object = {maintown1copy: "maintown1", maintown2copy: "maintown2", yabistudycopy: "yabistudy"};

      /**
       * Go to a scene. The 2013 signature (the era scenes and task scripts
       * call it with all six): reload even when already in that room, isEt,
       * the direction to face on arrival, and extra data the next scene reads
       * as loadedSceneInfo.extInfo (e.g. taskIdFromTP from the task panel).
       * Asked for the room the player is in, without reload, it only
       * announces ENTER_SCENE_SHOWTIPS, as the later client does.
       */
      public function loadScene(sceneName:String, locationKey:String = "default", reload:Boolean = false, isEt:Boolean = false,
            faceDirection:* = "ld", extInfo:Object = null):void
      {
         if (busy) return;
         if (STAND_INS[sceneName] != null) sceneName = STAND_INS[sceneName];
         if (!reload && loadedSceneInfo != null && loadedSceneInfo.sceneName == sceneName && extInfo == null)
         {
            dispatchEvent(new SceneManagerEvent(SceneManagerEvent.ENTER_SCENE_SHOWTIPS, {sceneInfo: loadedSceneInfo}));
            return;
         }
         var cfg:ConfigReader = ConfigReader.instance;
         var swf:String = cfg.getSceneSwf(sceneName);
         if (swf == null || swf == "")
         {
            trace("[scene] no scene named " + sceneName + " in config.xml");
            dispatchEvent(new SceneManagerEvent(SceneManagerEvent.ON_JOIN_ROOM_ERROR, {sceneName: sceneName}));
            return;
         }
         var room:String = cfg.getSceneRoom(sceneName) || sceneName;
         var info:SceneInfo;
         if (_nextFB != null)
         {
            var fb:FBSceneInfo = new FBSceneInfo(sceneName, room, swf);
            fb.fbName = _nextFB.fbName;
            fb.teamKey = _nextFB.teamKey;
            info = fb;
            _nextFB = null;
         }
         else
         {
            info = new SceneInfo(sceneName, room, swf);
         }
         info.locationKey = locationKey;
         if (faceDirection is String && faceDirection != "") info.faceDirection = faceDirection;
         info.extInfo = extInfo;
         var desc:String = cfg.getSceneDescription(sceneName);
         loadSceneWith(info, {desc: desc ? "正在前往" + desc + "……" : "请稍等……"});
      }

      /**
       * Load a scene described by info (its SWF, room and location), e.g. a
       * home from house/houseloader. hooks (all optional): desc, the loading
       * text; prepare(info, go), called once the scene is built and before
       * its room is joined (go() continues); entered(info), called after the
       * scene is shown and before SCENE_INITED.
       */
      public function loadSceneWith(info:SceneInfo, hooks:Object = null):void
      {
         if (busy) return;
         if (loadedGameInfo != null)
         {
            // Going elsewhere from inside a mini game (a task, a test): the game goes away.
            var g:Object = loadedGameInfo;
            loadedGameInfo = null;
            if (gameLayer != null && gameLayer.parent != null) gameLayer.parent.removeChild(gameLayer);
            gameLayer = null;
            SoundMixer.stopAll();
            isSuspend = false;
            dispatchEvent(new SceneManagerEvent(SceneManagerEvent.UNLOAD_GAME, {gameInfo: g}));
         }
         busy = true;
         loadingInfo = info;
         loadingHooks = hooks || {};
         var e:SceneManagerEvent = new SceneManagerEvent(SceneManagerEvent.ON_LOADING_SCENE, {sceneName: info.sceneName, SceneInfo: info});
         dispatchEvent(e);
         if (e.params.cancel)
         {
            busy = false;
            loadingInfo = null;
            return;
         }
         var token:SceneInfo = loadingInfo;
         var swf:String = info.swf;
         fileArrived = false;
         SimpleCustomLoader.loadSingleResource(swf, null, LoadingSpriteType.FULL_SCREEN, loadingHooks.desc || "请稍等……", onSceneLoaded, this,
            function():void
            {
               // Called on success, error and cancel alike; the callback follows only on success.
               setTimeout(function():void
               {
                  if (busy && loadingInfo == token && !fileArrived) fail("scene file " + swf, new Error("not loaded"));
               }, 0);
            });
      }

      private function onSceneLoaded(content:Object):void
      {
         fileArrived = true;
         var doc:DocSceneBase = content as DocSceneBase;
         if (doc == null && content != null && content.hasOwnProperty("content"))
         {
            doc = content["content"] as DocSceneBase;
         }
         if (doc == null)
         {
            busy = false;
            trace("[scene] " + loadingInfo.swf + " is not a scene document");
            dispatchEvent(new SceneManagerEvent(SceneManagerEvent.ON_JOIN_ROOM_ERROR, {sceneName: loadingInfo.sceneName}));
            return;
         }
         try
         {
            loadingInfo.doc = doc;
            loadingInfo.scene = doc.scene;
         }
         catch (err:Error)
         {
            fail("scene " + loadingInfo.sceneName + " (" + loadingInfo.swf + ") failed to build", err);
            return;
         }
         if (loadingHooks.prepare is Function)
         {
            var token:SceneInfo = loadingInfo;
            try
            {
               loadingHooks.prepare(loadingInfo, function():void
               {
                  if (loadingInfo == token) joinLoadedScene();
               });
            }
            catch (err:Error)
            {
               fail("scene " + loadingInfo.sceneName + " (" + loadingInfo.swf + ") could not be prepared", err);
            }
            return;
         }
         joinLoadedScene();
      }

      private function joinLoadedScene():void
      {
         RLog.log("scene: built " + loadingInfo.sceneName + ", joining room " + loadingInfo.roomName);
         unloadCurrent();
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener(SocketClientEvent.onJoinRoom, onJoinRoom);
         sc.addEventListener(SocketClientEvent.onJoinRoomError, onJoinRoomError);
         sc.joinRoom(loadingInfo.roomName);
      }

      private function unloadCurrent():void
      {
         if (loadedSceneInfo == null) return;
         var old:SceneInfo = loadedSceneInfo;
         loadedSceneInfo = null;
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.UNLOAD_SCENE, {sceneName: old.sceneName}));
         PlayerManager.getInstance().clear();
         if (old.scene)
         {
            old.scene.leave();
            if (old.scene.parent) old.scene.parent.removeChild(old.scene);
         }
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.DISPOSED_SCENE, {sceneName: old.sceneName}));
      }

      private function onJoinRoom(e:SocketClientEvent):void
      {
         stopListening();
         var info:SceneInfo = loadingInfo;
         loadingInfo = null;
         var scene:SceneBase = info.scene;
         var layer:Sprite = LayerManager.getBaseScene();
         while (layer.numChildren > 0) layer.removeChildAt(0);
         layer.addChild(scene);
         var size:Object = ConfigReader.instance.getBigScene(info.sceneName);
         var loc:Point = scene.locationFor(info.locationKey);
         var room:Room = SocketClient.instance.activeRoom;
         loadedSceneInfo = info;
         if (!info.inHouse)
         {
            history.push(info.sceneName);
            if (history.length > 10) history.shift();
         }
         try
         {
            PlayerManager.getInstance().populate(room, scene.playerLayer, loc.x, loc.y, scene.getPlayerGenerator());
            scene.enter(int(size.width), int(size.height));
         }
         catch (err:Error)
         {
            RLog.error("scene.enter " + info.sceneName, err);
         }
         var hooks:Object = loadingHooks;
         loadingHooks = {};
         if (hooks.entered is Function)
         {
            try { hooks.entered(info); } catch (err2:Error) { RLog.error("scene hook " + info.sceneName, err2); }
         }
         busy = false;
         RLog.log("scene: entered " + info.sceneName + " at " + loc.x + "," + loc.y);
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.SCENE_INITED, {sceneName: info.sceneName}));
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.SCENE_OPENED, {sceneName: info.sceneName}));
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.TASK_SCENE_INITED, {sceneName: info.sceneName}));
      }

      /** The scene cannot be shown (usually its 2013 code needs a module that is lost). */
      private function fail(what:String, err:Error):void
      {
         busy = false;
         loadingHooks = {};
         RLog.error(what, err);
         var name:String = loadingInfo ? loadingInfo.sceneName : null;
         loadingInfo = null;
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.ON_JOIN_ROOM_ERROR, {sceneName: name}));
         if (loadedSceneInfo == null)
         {
            var i:int = FALLBACK_SCENES.indexOf(name);
            var next:String = FALLBACK_SCENES[i + 1];
            if (next) loadScene(next);
            return;
         }
         RNotice.show(LayerManager.getBaseScene().stage, "这里还没有修复好，暂时不能进入哦！");
      }

      private function onJoinRoomError(e:SocketClientEvent):void
      {
         stopListening();
         busy = false;
         loadingHooks = {};
         dispatchEvent(new SceneManagerEvent(SceneManagerEvent.ON_JOIN_ROOM_ERROR, {sceneName: loadingInfo ? loadingInfo.sceneName : null, error: e.params}));
         loadingInfo = null;
      }

      private function stopListening():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener(SocketClientEvent.onJoinRoom, onJoinRoom);
         sc.removeEventListener(SocketClientEvent.onJoinRoomError, onJoinRoomError);
      }
   }
}
