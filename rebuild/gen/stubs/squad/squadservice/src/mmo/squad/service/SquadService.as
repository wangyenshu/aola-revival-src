package mmo.squad.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.squad.*;
   import mmo.interfaces.squad.ISquadService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for SquadService. Module squad/squadservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.squad.ISquadService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class SquadService extends EventDispatcher implements ISquadService
   {
      private var _isInBattle:Boolean = false;
      private var _isFightingSquadBoss:Boolean = false;
      private var _fightBossId:int = 0;
      private var _isHaveJoinedSquad:Boolean = false;
      public function SquadService()
      {
         super();
      }

      public function leaveSquad() : void
      {
         RLog.stub("SquadService.leaveSquad");
      }

      public function joinRequest(param1:int) : void
      {
         RLog.stub("SquadService.joinRequest");
      }

      public function get isInBattle() : Boolean
      {
         RLog.stub("SquadService.isInBattle");
         return this._isInBattle;
      }

      public function invite(param1:String) : void
      {
         RLog.stub("SquadService.invite");
      }

      public function get isFightingSquadBoss() : Boolean
      {
         RLog.stub("SquadService.isFightingSquadBoss");
         return this._isFightingSquadBoss;
      }

      public function getComfirmModalDialog(param1:String, param2:Function = null, param3:Boolean = false) : void
      {
         RLog.stub("SquadService.getComfirmModalDialog");
      }

      public function set isInBattle(param1:Boolean) : void
      {
         this._isInBattle = param1;
      }

      public function getAllMembersOfOtherSquad(param1:int) : void
      {
         RLog.stub("SquadService.getAllMembersOfOtherSquad");
      }

      public function getMyTeamAllInfo() : void
      {
         RLog.stub("SquadService.getMyTeamAllInfo");
      }

      public function getIconSprite(param1:String, param2:Function = null) : Sprite
      {
         RLog.stub("SquadService.getIconSprite");
         return null;
      }

      public function getOtherSquadInfo(param1:int) : void
      {
         RLog.stub("SquadService.getOtherSquadInfo");
      }

      public function showSquadPanel() : void
      {
         RLog.stub("SquadService.showSquadPanel");
      }

      public function get fightBossId() : int
      {
         RLog.stub("SquadService.fightBossId");
         return this._fightBossId;
      }

      public function showContributionAndHonorTip(param1:int = 0, param2:int = 0, param3:int = 0) : void
      {
         RLog.stub("SquadService.showContributionAndHonorTip");
      }

      public function getMyMember() : SquadMemberInfo
      {
         RLog.stub("SquadService.getMyMember");
         return null;
      }

      public function addSquadPanelMsg(param1:Object) : void
      {
         RLog.stub("SquadService.addSquadPanelMsg");
      }

      public function createSquad() : void
      {
         RLog.stub("SquadService.createSquad");
      }

      public function get isHaveJoinedSquad() : Boolean
      {
         RLog.stub("SquadService.isHaveJoinedSquad");
         return this._isHaveJoinedSquad;
      }

      public function showMsgPanel() : void
      {
         RLog.stub("SquadService.showMsgPanel");
      }

      public function searchAllSquad(param1:int, param2:Boolean) : void
      {
         RLog.stub("SquadService.searchAllSquad");
      }

      public function getApplyName() : void
      {
         RLog.stub("SquadService.getApplyName");
      }

      public function searchSquadById(param1:String) : void
      {
         RLog.stub("SquadService.searchSquadById");
      }

      public function deleteMember(param1:String) : void
      {
         RLog.stub("SquadService.deleteMember");
      }

      public function setShieldState(param1:Boolean) : void
      {
         RLog.stub("SquadService.setShieldState");
      }

      public function setSquadTalkPanelOpenState(param1:Boolean) : void
      {
         RLog.stub("SquadService.setSquadTalkPanelOpenState");
      }

      public function getMySquadNumberOfPosition(param1:int) : int
      {
         RLog.stub("SquadService.getMySquadNumberOfPosition");
         return 0;
      }

      public function set isFightingSquadBoss(param1:Boolean) : void
      {
         this._isFightingSquadBoss = param1;
      }

      public function auditJoinApplication(param1:String, param2:Boolean, param3:int) : void
      {
         RLog.stub("SquadService.auditJoinApplication");
      }

      public function getTips(param1:String, param2:Function = null, param3:Boolean = false) : void
      {
         RLog.stub("SquadService.getTips");
      }

      public function getPanelMsgArr() : Array
      {
         RLog.stub("SquadService.getPanelMsgArr");
         return [];
      }

      public function authorizePosition(param1:String, param2:int) : void
      {
         RLog.stub("SquadService.authorizePosition");
      }

      public function getSquadTalkPanelOpenState() : Boolean
      {
         RLog.stub("SquadService.getSquadTalkPanelOpenState");
         return false;
      }

      public function replyInvition(param1:String, param2:Boolean, param3:int) : void
      {
         RLog.stub("SquadService.replyInvition");
      }

      public function set fightBossId(param1:int) : void
      {
         this._fightBossId = param1;
      }

      public function getMySquad() : SquadInfo
      {
         RLog.stub("SquadService.getMySquad");
         return null;
      }

      public function getShieldState() : Boolean
      {
         RLog.stub("SquadService.getShieldState");
         return false;
      }

      public function getMyAllMembers() : Array
      {
         RLog.stub("SquadService.getMyAllMembers");
         return [];
      }

      public function modifySlogan(param1:String) : void
      {
         RLog.stub("SquadService.modifySlogan");
      }

      public function init() : void
      {
         RLog.stub("SquadService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
