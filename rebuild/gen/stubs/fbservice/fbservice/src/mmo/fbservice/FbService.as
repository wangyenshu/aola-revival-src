package mmo.fbservice
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.fb.*;
   import mmo.interfaces.fb.IFbService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FbService. Module fbservice/fbservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.fb.IFbService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FbService extends EventDispatcher implements IFbService
   {
      private var _currentFbName:String;
      private var _isInFb:Boolean = false;
      private var _currentFbLevel:int = 0;
      private var _currentFbId:int = 0;
      public function FbService()
      {
         super();
      }

      public function get currentFbName() : String
      {
         RLog.stub("FbService.currentFbName");
         return this._currentFbName;
      }

      public function joinFb(param1:int, param2:String, param3:int, param4:Object) : void
      {
         RLog.stub("FbService.joinFb");
      }

      public function healHpAndPP(param1:Object) : void
      {
         RLog.stub("FbService.healHpAndPP");
      }

      public function get isInFb() : Boolean
      {
         RLog.stub("FbService.isInFb");
         return this._isInFb;
      }

      public function tryFinFb(param1:Object) : void
      {
         RLog.stub("FbService.tryFinFb");
      }

      public function get currentFbLevel() : int
      {
         RLog.stub("FbService.currentFbLevel");
         return this._currentFbLevel;
      }

      public function get currentFbId() : int
      {
         RLog.stub("FbService.currentFbId");
         return this._currentFbId;
      }

      public function tryGetCaseAtCurrentScene(param1:Object) : void
      {
         RLog.stub("FbService.tryGetCaseAtCurrentScene");
      }

      public function leaveFb(param1:Object) : void
      {
         RLog.stub("FbService.leaveFb");
      }

      public function addCurrentWildPets(param1:Array) : void
      {
         RLog.stub("FbService.addCurrentWildPets");
      }

      public function removeCondition(param1:IClearCondition) : void
      {
         RLog.stub("FbService.removeCondition");
      }

      public function registerCondition(param1:int, param2:Object) : IClearCondition
      {
         RLog.stub("FbService.registerCondition");
         return null;
      }

      public function tryGetbestPraise(param1:int) : void
      {
         RLog.stub("FbService.tryGetbestPraise");
      }

      public function addFollower(param1:int) : DisplayObject
      {
         RLog.stub("FbService.addFollower");
         return null;
      }

      public function init() : void
      {
         RLog.stub("FbService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
