package mmo.family.register
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.family.*;
   import mmo.interfaces.family.IFamilyRegisterService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FamilyRegister. Module family/register.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.family.IFamilyRegisterService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class RegisterService extends EventDispatcher implements IFamilyRegisterService
   {
      public function RegisterService()
      {
         super();
      }

      public function showRegisterPanel() : void
      {
         RLog.stub("RegisterService.showRegisterPanel");
      }

   }
}
