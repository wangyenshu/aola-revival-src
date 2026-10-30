package mmo.fbteam.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fbteam.*;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FBTeamService. Module fbteam/fbteamservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fbteam.IFBTeamService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FBTeamService extends EventDispatcher implements IFBTeamService
   {
      private var _currentFBInfo:*;
      private var _currentStep:int = 0;
      private var _isRunning:Boolean = false;
      public function FBTeamService()
      {
         super();
      }

      public function stop() : void
      {
         RLog.stub("FBTeamService.stop");
      }

      public function get currentFBInfo() : Object
      {
         RLog.stub("FBTeamService.currentFBInfo");
         return this._currentFBInfo as Object;
      }

      public function get currentStep() : int
      {
         RLog.stub("FBTeamService.currentStep");
         return this._currentStep;
      }

      public function set currentFBInfo(param1:Object) : void
      {
         this._currentFBInfo = param1;
      }

      public function set currentStep(param1:int) : void
      {
         this._currentStep = param1;
      }

      public function tryGetCurrentCase(param1:Object) : void
      {
         RLog.stub("FBTeamService.tryGetCurrentCase");
      }

      public function finishFB(param1:Object) : void
      {
         RLog.stub("FBTeamService.finishFB");
      }

      public function play() : void
      {
         RLog.stub("FBTeamService.play");
      }

      public function get isRunning() : Boolean
      {
         RLog.stub("FBTeamService.isRunning");
         return this._isRunning;
      }

      public function pause() : void
      {
         RLog.stub("FBTeamService.pause");
      }

      public function tryGetbestPraise(param1:int) : void
      {
         RLog.stub("FBTeamService.tryGetbestPraise");
      }

      public function startup() : void
      {
         RLog.stub("FBTeamService.startup");
      }

      public function init() : void
      {
         RLog.stub("FBTeamService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
