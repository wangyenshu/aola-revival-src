package mmo.fbservice.auto
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fb.*;
   import mmo.interfaces.fb.IFbStepService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FbStepService. Module fbservice/fbservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fb.IFbStepService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FbStepService extends EventDispatcher implements IFbStepService
   {
      private var _currentStep:int = 0;
      private var _pauseKey:Boolean = false;
      private var _lock:Boolean = false;
      public function FbStepService()
      {
         super();
      }

      public function get currentStep() : int
      {
         RLog.stub("FbStepService.currentStep");
         return this._currentStep;
      }

      public function nextStep() : void
      {
         RLog.stub("FbStepService.nextStep");
      }

      public function get pauseKey() : Boolean
      {
         RLog.stub("FbStepService.pauseKey");
         return this._pauseKey;
      }

      public function get lock() : Boolean
      {
         RLog.stub("FbStepService.lock");
         return this._lock;
      }

      public function helloTalkReset() : void
      {
         RLog.stub("FbStepService.helloTalkReset");
      }

      public function set pauseKey(param1:Boolean) : void
      {
         this._pauseKey = param1;
      }

      public function play() : void
      {
         RLog.stub("FbStepService.play");
      }

      public function pause() : void
      {
         RLog.stub("FbStepService.pause");
      }

      public function jumpStep(param1:int) : void
      {
         RLog.stub("FbStepService.jumpStep");
      }

      public function set lock(param1:Boolean) : void
      {
         this._lock = param1;
      }

      public function dispose() : void
      {
         RLog.stub("FbStepService.dispose");
      }

      public function init() : void
      {
         RLog.stub("FbStepService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
