package mmo.petnickname
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.nickname.*;
   import mmo.interfaces.pet.nickname.IPetNicknameService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetNicknameService. Module pet/petnicknameservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.nickname.IPetNicknameService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetNicknameService extends EventDispatcher implements IPetNicknameService
   {
      public function PetNicknameService()
      {
         super();
      }

      public function showChangeNicknamePanel(param1:PetBriefInfo) : void
      {
         RLog.stub("PetNicknameService.showChangeNicknamePanel");
      }

   }
}
