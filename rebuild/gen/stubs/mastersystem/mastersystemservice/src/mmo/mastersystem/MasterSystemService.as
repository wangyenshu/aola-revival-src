package mmo.mastersystem
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.mastersystem.*;
   import mmo.interfaces.mastersystem.IMasterSystemService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MasterSystemService. Module mastersystem/mastersystemservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.mastersystem.IMasterSystemService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MasterSystemService extends EventDispatcher implements IMasterSystemService
   {
      private var _giftBagState:int = 0;
      private var _myStudentName:String;
      private var _teacherLevel:int = 0;
      private var _responsibilityType:int = 0;
      private var _isPassTest:*;
      private var _myMasterName:*;
      private var _myMasterNickName:*;
      private var _myStudentNickName:*;
      private var _numberOfStudent:int = 0;
      public function MasterSystemService()
      {
         super();
      }

      public function get giftBagState() : int
      {
         RLog.stub("MasterSystemService.giftBagState");
         return this._giftBagState;
      }

      public function get myStudentName() : String
      {
         RLog.stub("MasterSystemService.myStudentName");
         return this._myStudentName;
      }

      public function get teacherLevel() : int
      {
         RLog.stub("MasterSystemService.teacherLevel");
         return this._teacherLevel;
      }

      public function set teacherLevel(param1:int) : void
      {
         this._teacherLevel = param1;
      }

      public function get responsibilityType() : int
      {
         RLog.stub("MasterSystemService.responsibilityType");
         return this._responsibilityType;
      }

      public function set isPassTest(param1:Boolean) : void
      {
         this._isPassTest = param1;
      }

      public function get isPassTest() : Boolean
      {
         RLog.stub("MasterSystemService.isPassTest");
         return this._isPassTest;
      }

      public function set responsibilityType(param1:int) : void
      {
         this._responsibilityType = param1;
      }

      public function set myMasterName(param1:String) : void
      {
         this._myMasterName = param1;
      }

      public function set myStudentName(param1:String) : void
      {
         this._myStudentName = param1;
      }

      public function set myMasterNickName(param1:String) : void
      {
         this._myMasterNickName = param1;
      }

      public function get myMasterName() : String
      {
         RLog.stub("MasterSystemService.myMasterName");
         return this._myMasterName;
      }

      public function set myStudentNickName(param1:String) : void
      {
         this._myStudentNickName = param1;
      }

      public function get numberOfStudent() : int
      {
         RLog.stub("MasterSystemService.numberOfStudent");
         return this._numberOfStudent;
      }

      public function get myMasterNickName() : String
      {
         RLog.stub("MasterSystemService.myMasterNickName");
         return this._myMasterNickName;
      }

      public function get myStudentNickName() : String
      {
         RLog.stub("MasterSystemService.myStudentNickName");
         return this._myStudentNickName;
      }

      public function init() : void
      {
         RLog.stub("MasterSystemService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
