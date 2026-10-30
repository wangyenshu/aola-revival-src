package mmo.buttonhandler
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.buttonhandler.*;
   import mmo.interfaces.buttonhandler.IButtonHandler;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ButtonHandlerService. Module buttonhandler/buttonhandlerservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.buttonhandler.IButtonHandler) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ButtonHandlerService extends EventDispatcher implements IButtonHandler
   {
      public function ButtonHandlerService()
      {
         super();
      }

      public function handleButtonByName(param1:String, param2:Object = null) : void
      {
         RLog.stub("ButtonHandlerService.handleButtonByName");
      }

   }
}
