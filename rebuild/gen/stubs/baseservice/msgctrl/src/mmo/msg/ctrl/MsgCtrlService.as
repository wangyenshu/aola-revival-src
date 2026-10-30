package mmo.msg.ctrl
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.msg.*;
   import mmo.interfaces.msg.IMsgCtrlService;
   import mmo.interfaces.msg.responder.IMsgResponder;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MsgCtrlService. Module baseservice/msgctrl.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.msg.IMsgCtrlService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MsgCtrlService extends EventDispatcher implements IMsgCtrlService
   {
      public function MsgCtrlService()
      {
         super();
      }

      public function getResponder(param1:String) : IMsgResponder
      {
         RLog.stub("MsgCtrlService.getResponder");
         return null;
      }

   }
}
