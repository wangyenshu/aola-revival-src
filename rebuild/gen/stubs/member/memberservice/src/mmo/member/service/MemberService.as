package mmo.member.service
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.member.*;
   import mmo.interfaces.member.IMemberService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MemberService. Module member/memberservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.member.IMemberService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MemberService extends EventDispatcher implements IMemberService
   {
      public function MemberService()
      {
         super();
      }

      public function showOpenServices() : void
      {
         RLog.stub("MemberService.showOpenServices");
      }

      public function showBalance() : void
      {
         RLog.stub("MemberService.showBalance");
      }

      public function showExpenditrues() : void
      {
         RLog.stub("MemberService.showExpenditrues");
      }

   }
}
