package mmo.user.namemanager
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.user.*;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserNameManager. Module user/usernamemanager.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.user.IUserNameManager) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserNameManager extends EventDispatcher implements IUserNameManager
   {
      public function UserNameManager()
      {
         super();
      }

      public function setNickName(param1:String, param2:String) : void
      {
         RLog.stub("UserNameManager.setNickName");
      }

      public function getSign() : void
      {
         RLog.stub("UserNameManager.getSign");
      }

      public function getNickName(param1:String) : String
      {
         RLog.stub("UserNameManager.getNickName");
         return "";
      }

      public function getNicknameByName(param1:String) : void
      {
         RLog.stub("UserNameManager.getNicknameByName");
      }

      public function getNameById(param1:Array) : void
      {
         RLog.stub("UserNameManager.getNameById");
      }

      public function changeNickname(param1:String) : void
      {
         RLog.stub("UserNameManager.changeNickname");
      }

      public function init() : void
      {
         RLog.stub("UserNameManager.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
