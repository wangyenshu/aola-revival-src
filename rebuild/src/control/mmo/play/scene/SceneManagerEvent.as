package mmo.play.scene
{
   import flash.events.Event;

   /** REBUILT. Scene life-cycle notifications (2013 names and values). */
   public final class SceneManagerEvent extends Event
   {
      public static const ON_JOIN_ROOM_ERROR:String = "on_join_room_error";
      public static const ON_LOADING_SCENE:String = "onLoadingScene";
      public static const SCENE_PRERENDER:String = "onScenePreRender";
      public static const SCENE_RENDER:String = "onSceneRender";
      public static const SCENE_INITED:String = "onSceneInited";
      public static const SCENE_OPENED:String = "onSceneOpened";
      public static const TASK_SCENE_INITED:String = "onTaskSceneInited";
      public static const UNLOAD_SCENE:String = "onUnloadScene";
      public static const DISPOSED_SCENE:String = "onDisposedScene";
      public static const GAME_INITED:String = "onGameInited";
      public static const UNLOAD_GAME:String = "onUnloadGame";
      public static const ENTER_SCENE_SHOWTIPS:String = "onEnterSceneShowTips";
      public static const LOADING_VALIDATED:String = "onLoadingSceneValidated";
      public static const SUSPEND_STATE_CHANGED:String = "SuspendStateChanged";

      public var params:Object;

      public function SceneManagerEvent(type:String, params:Object = null, cancelable:Boolean = false)
      {
         super(type, false, cancelable);
         this.params = params || {};
      }

      public function get sceneName():String
      {
         return params.sceneName;
      }

      override public function clone():Event
      {
         return new SceneManagerEvent(type, params, cancelable);
      }
   }
}
