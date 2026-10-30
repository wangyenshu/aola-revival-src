package mmo.talk
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.ITalk;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for TalkService. Module talk/talk.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.ITalk) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class TalkService extends EventDispatcher implements ITalk
   {
      public function TalkService()
      {
         super();
      }

      public function getMessage(param1:String, param2:int = 0) : Array
      {
         RLog.stub("TalkService.getMessage");
         return [];
      }

      public function hasRegister(param1:String, param2:int = 0) : Boolean
      {
         RLog.stub("TalkService.hasRegister");
         return false;
      }

      public function push(param1:String, param2:String, param3:int) : void
      {
         RLog.stub("TalkService.push");
      }

      public function showTalkPanel(param1:String, param2:int = 0) : void
      {
         RLog.stub("TalkService.showTalkPanel");
      }

      public function removeMessageLayout(param1:String, param2:int) : void
      {
         RLog.stub("TalkService.removeMessageLayout");
      }

      public function registerMessageLayout(param1:String, param2:int, param3:IMessageLayout) : void
      {
         RLog.stub("TalkService.registerMessageLayout");
      }

   }
}
