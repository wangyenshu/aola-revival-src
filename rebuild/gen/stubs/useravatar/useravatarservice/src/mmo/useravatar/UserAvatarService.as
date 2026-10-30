package mmo.useravatar
{
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.useravatar.*;
   import mmo.interfaces.useravatar.IUserAvatarService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for UserAvatarService. Module useravatar/useravatarservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.useravatar.IUserAvatarService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class UserAvatarService extends EventDispatcher implements IUserAvatarService
   {
      public function UserAvatarService()
      {
         super();
      }

      public function showUserAvatar(param1:String, param2:MovieClip, param3:Number, param4:Number, param5:int, param6:int) : void
      {
         RLog.stub("UserAvatarService.showUserAvatar");
      }

   }
}
