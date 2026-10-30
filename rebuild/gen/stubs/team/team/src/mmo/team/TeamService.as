package mmo.team
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.team.*;
   import mmo.interfaces.team.ITeamService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TeamService. Module team/team.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.team.ITeamService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TeamService extends EventDispatcher implements ITeamService
   {
      private var _isRefuse:Boolean = false;
      public function TeamService()
      {
         super();
      }

      public function isMember() : Boolean
      {
         RLog.stub("TeamService.isMember");
         return false;
      }

      public function joinRequest(param1:String) : void
      {
         RLog.stub("TeamService.joinRequest");
      }

      public function invite(param1:String) : void
      {
         RLog.stub("TeamService.invite");
      }

      public function appointLeader(param1:String) : void
      {
         RLog.stub("TeamService.appointLeader");
      }

      public function cancelJoinRequest(param1:String) : void
      {
         RLog.stub("TeamService.cancelJoinRequest");
      }

      public function deleteMember(param1:String) : void
      {
         RLog.stub("TeamService.deleteMember");
      }

      public function joinOrInviteReady(param1:String) : void
      {
         RLog.stub("TeamService.joinOrInviteReady");
      }

      public function cancelInviteRequest(param1:String) : void
      {
         RLog.stub("TeamService.cancelInviteRequest");
      }

      public function showRoomTeamPanel(param1:Sprite, param2:Sprite, param3:int = 5, param4:Sprite = null, param5:int = 5, param6:int = -1, param7:int = -1) : void
      {
         RLog.stub("TeamService.showRoomTeamPanel");
      }

      public function unReady() : void
      {
         RLog.stub("TeamService.unReady");
      }

      public function isLeader() : Boolean
      {
         RLog.stub("TeamService.isLeader");
         return false;
      }

      public function leaveTeam() : void
      {
         RLog.stub("TeamService.leaveTeam");
      }

      public function refuseInvite(param1:Boolean) : void
      {
         RLog.stub("TeamService.refuseInvite");
      }

      public function get isRefuse() : Boolean
      {
         RLog.stub("TeamService.isRefuse");
         return this._isRefuse;
      }

      public function getJoinOrInviteReady() : Boolean
      {
         RLog.stub("TeamService.getJoinOrInviteReady");
         return false;
      }

      public function createTeam() : void
      {
         RLog.stub("TeamService.createTeam");
      }

      public function getJoinOrInvite() : String
      {
         RLog.stub("TeamService.getJoinOrInvite");
         return "";
      }

      public function getTeamButton(param1:String) : MovieClip
      {
         RLog.stub("TeamService.getTeamButton");
         return null;
      }

      public function getUserTeam(param1:String) : UserTeamInfo
      {
         RLog.stub("TeamService.getUserTeam");
         return null;
      }

      public function getMyTeam() : TeamInfo
      {
         RLog.stub("TeamService.getMyTeam");
         return null;
      }

      public function init() : void
      {
         RLog.stub("TeamService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
