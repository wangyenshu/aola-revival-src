package mmo.msg.doc
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.msg.*;
   import mmo.interfaces.msg.IMsgDocService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for MsgDocService. Module baseservice/msgdoc.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.msg.IMsgDocService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class MsgDocService extends EventDispatcher implements IMsgDocService
   {
      public function MsgDocService()
      {
         super();
      }

      public function popMsg(param1:Array = null, param2:int = 4096) : Array
      {
         RLog.stub("MsgDocService.popMsg");
         return [];
      }

      public function countMsg(param1:Array = null) : int
      {
         RLog.stub("MsgDocService.countMsg");
         return 0;
      }

      public function getMsgByProp(param1:Array = null, param2:String = "type", param3:int = 4096) : Array
      {
         RLog.stub("MsgDocService.getMsgByProp");
         return [];
      }

      public function delMsg(param1:Array = null) : void
      {
         RLog.stub("MsgDocService.delMsg");
      }

      public function delMsgByProp(param1:Array = null, param2:String = "key") : void
      {
         RLog.stub("MsgDocService.delMsgByProp");
      }

      public function popMsgByProp(param1:Array = null, param2:String = "type", param3:int = 4096) : Array
      {
         RLog.stub("MsgDocService.popMsgByProp");
         return [];
      }

      public function getMsg(param1:Array = null, param2:int = 4096) : Array
      {
         RLog.stub("MsgDocService.getMsg");
         return [];
      }

      public function countMsgByProp(param1:Array, param2:String = "type") : int
      {
         RLog.stub("MsgDocService.countMsgByProp");
         return 0;
      }

      public function addMsg(param1:Object, param2:int, param3:String = null) : void
      {
         RLog.stub("MsgDocService.addMsg");
      }

   }
}
