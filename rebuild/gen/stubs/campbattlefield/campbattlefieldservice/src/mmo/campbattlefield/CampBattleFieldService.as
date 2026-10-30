package mmo.campbattlefield
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.campbattlefield.*;
   import mmo.interfaces.campbattlefield.ICampBattleFieldService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for CampBattleFieldService. Module campbattlefield/campbattlefieldservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.campbattlefield.ICampBattleFieldService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class CampBattleFieldService extends EventDispatcher implements ICampBattleFieldService
   {
      private var _curRoom:int = 0;
      private var _curTable:*;
      public function CampBattleFieldService()
      {
         super();
      }

      public function get curRoom() : int
      {
         RLog.stub("CampBattleFieldService.curRoom");
         return this._curRoom;
      }

      public function addGameEndListener() : void
      {
         RLog.stub("CampBattleFieldService.addGameEndListener");
      }

      public function set curRoom(param1:int) : void
      {
         this._curRoom = param1;
      }

      public function addBeKickedOutListener() : void
      {
         RLog.stub("CampBattleFieldService.addBeKickedOutListener");
      }

      public function disposeBeKickedOutListener() : void
      {
         RLog.stub("CampBattleFieldService.disposeBeKickedOutListener");
      }

      public function set curTable(param1:int) : void
      {
         this._curTable = param1;
      }

      public function get curTable() : int
      {
         RLog.stub("CampBattleFieldService.curTable");
         return this._curTable;
      }

      public function init() : void
      {
         RLog.stub("CampBattleFieldService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
