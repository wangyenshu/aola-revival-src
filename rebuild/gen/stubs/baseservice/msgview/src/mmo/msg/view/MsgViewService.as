package mmo.msg.view
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.msg.*;
   import mmo.interfaces.msg.IMsgViewService;
   import mmo.interfaces.msg.decorator.IMsgDecorator;
   import mmo.interfaces.msg.dialog.IMsgDialog;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MsgViewService. Module baseservice/msgview.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.msg.IMsgViewService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MsgViewService extends EventDispatcher implements IMsgViewService
   {
      public function MsgViewService()
      {
         super();
      }

      public function getDecorator(param1:String) : IMsgDecorator
      {
         RLog.stub("MsgViewService.getDecorator");
         return null;
      }

      public function getDialog(param1:String) : IMsgDialog
      {
         RLog.stub("MsgViewService.getDialog");
         return null;
      }

   }
}
