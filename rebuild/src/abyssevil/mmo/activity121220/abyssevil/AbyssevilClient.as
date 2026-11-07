package mmo.activity121220.abyssevil
{
   import mmo.framework.comm.SocketClient;
   
   public class AbyssevilClient
   {
      
      private static var _instance:AbyssevilClient;
      
      private static const EXTENSION:String = "PeriodicActiveExtension";
      
      public static const CMD_GET_INFO:String = "mdk1224-1";
      
      public static const CMD_WAKE_UP_DRAGON:String = "mdk1224-2";
      
      public function AbyssevilClient()
      {
         super();
      }
      
      public static function instance() : AbyssevilClient
      {
         if(_instance == null)
         {
            _instance = new AbyssevilClient();
         }
         return _instance;
      }
      
      public function getInfo() : void
      {
         SocketClient.instance.sendXtMessage(EXTENSION,CMD_GET_INFO,null);
      }
      
      public function wakeupDragon() : void
      {
         SocketClient.instance.sendXtMessage(EXTENSION,CMD_WAKE_UP_DRAGON,null);
      }
   }
}

