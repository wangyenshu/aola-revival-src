package mmo.follow
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.follow.*;
   import mmo.interfaces.follow.IFollowService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FollowService. Module baseservice/follow.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.follow.IFollowService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FollowService extends EventDispatcher implements IFollowService
   {
      public function FollowService()
      {
         super();
      }

      public function inviteRide(param1:String) : Boolean
      {
         RLog.stub("FollowService.inviteRide");
         return false;
      }

      public function allowInvite() : void
      {
         RLog.stub("FollowService.allowInvite");
      }

      public function refuseInvite() : void
      {
         RLog.stub("FollowService.refuseInvite");
      }

      public function mouseInviteRide() : void
      {
         RLog.stub("FollowService.mouseInviteRide");
      }

      public function init() : void
      {
         RLog.stub("FollowService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
