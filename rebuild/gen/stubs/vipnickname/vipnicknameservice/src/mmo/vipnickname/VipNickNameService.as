package mmo.vipnickname
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.vip.*;
   import mmo.interfaces.vip.IVipNickNameService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for VipNickNameService. Module vipnickname/vipnicknameservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.vip.IVipNickNameService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class VipNickNameService extends EventDispatcher implements IVipNickNameService
   {
      public function VipNickNameService()
      {
         super();
      }

      public function setVipNickName(param1:String) : void
      {
         RLog.stub("VipNickNameService.setVipNickName");
      }

      public function showPanel() : void
      {
         RLog.stub("VipNickNameService.showPanel");
      }

      public function init() : void
      {
         RLog.stub("VipNickNameService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
