package mmo.fbteam.common.synchronize
{
   import flash.events.EventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   
   public class FBTeamSynchronizedEventDispatcher extends EventDispatcher
   {
      
      private static var _instance:FBTeamSynchronizedEventDispatcher = null;
      
      public function FBTeamSynchronizedEventDispatcher()
      {
         super();
      }
      
      public static function get instance() : FBTeamSynchronizedEventDispatcher
      {
         if(null == _instance)
         {
            _instance = new FBTeamSynchronizedEventDispatcher();
         }
         return _instance;
      }
      
      public function initListener() : void
      {
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.onCustomCommand);
      }
      
      private function onCustomCommand(param1:SocketClientEvent) : void
      {
         var _loc2_:Object = param1.params.obj;
         var _loc3_:String = param1.params.obj.customCmd;
         this.dispatchEvent(new FBTeamSynchronizedEvent(_loc2_.customCmd,_loc2_));
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.onCustomCommand);
         _instance = null;
      }
   }
}

