package mmo.fbservice.auto
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fb.*;
   import mmo.interfaces.fb.IFbSceneService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FbSceneService. Module fbservice/fbservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fb.IFbSceneService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FbSceneService extends EventDispatcher implements IFbSceneService
   {
      private var _taskMode:*;
      private var _difficulty:*;
      public function FbSceneService()
      {
         super();
      }

      public function set taskMode(param1:Boolean) : void
      {
         this._taskMode = param1;
      }

      public function updataSceneElement(param1:String, param2:Boolean = true, param3:Function = null, param4:Object = null) : void
      {
         RLog.stub("FbSceneService.updataSceneElement");
      }

      public function set difficulty(param1:int) : void
      {
         this._difficulty = param1;
      }

      public function get taskMode() : Boolean
      {
         RLog.stub("FbSceneService.taskMode");
         return this._taskMode;
      }

      public function get difficulty() : int
      {
         RLog.stub("FbSceneService.difficulty");
         return this._difficulty;
      }

      public function dispose() : void
      {
         RLog.stub("FbSceneService.dispose");
      }

      public function init() : void
      {
         RLog.stub("FbSceneService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
