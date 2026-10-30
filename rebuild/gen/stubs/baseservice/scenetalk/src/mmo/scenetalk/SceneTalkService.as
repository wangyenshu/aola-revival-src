package mmo.scenetalk
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.IService;
   import mmo.interfaces.scenetalk.*;
   import mmo.interfaces.scenetalk.ISceneTalkService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SceneTalkService. Module baseservice/scenetalk.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.scenetalk.ISceneTalkService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SceneTalkService extends EventDispatcher implements ISceneTalkService
   {
      private var _isTalkable:*;
      private var _isSmilable:Boolean = false;
      private var _errCounter:int = 0;
      public function SceneTalkService()
      {
         super();
      }

      public function set isTalkable(param1:Boolean) : void
      {
         this._isTalkable = param1;
      }

      public function get isSmilable() : Boolean
      {
         RLog.stub("SceneTalkService.isSmilable");
         return this._isSmilable;
      }

      public function set isSmilable(param1:Boolean) : void
      {
         this._isSmilable = param1;
      }

      public function smile(param1:int) : void
      {
         RLog.stub("SceneTalkService.smile");
      }

      public function say(param1:String) : void
      {
         RLog.stub("SceneTalkService.say");
      }

      public function get isTalkable() : Boolean
      {
         RLog.stub("SceneTalkService.isTalkable");
         return this._isTalkable;
      }

      public function getTalkMessageRec() : Array
      {
         RLog.stub("SceneTalkService.getTalkMessageRec");
         return [];
      }

      public function activate() : void
      {
         RLog.stub("SceneTalkService.activate");
      }

      public function deactivate() : void
      {
         RLog.stub("SceneTalkService.deactivate");
      }

      public function incErrCounter() : void
      {
         RLog.stub("SceneTalkService.incErrCounter");
      }

      public function get errCounter() : int
      {
         RLog.stub("SceneTalkService.errCounter");
         return this._errCounter;
      }

      public function init() : void
      {
         RLog.stub("SceneTalkService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
