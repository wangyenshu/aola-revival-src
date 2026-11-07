package mmo.starcoinexchange.fortunemanager.operate
{
   import mmo.framework.comm.SocketClient;
   
   public class FortuneManagerClient
   {
      
      private static var _instance:FortuneManagerClient;
      
      public static var cmdGetAccount:String = "getAccount";
      
      public static var cmdTakeAwayAccount:String = "takeAwawyAccount";
      
      public static var cmdDespositAccount:String = "despositAccount";
      
      private var extendsionName:String = "ScoreManager";
      
      public function FortuneManagerClient()
      {
         super();
         if(_instance != null)
         {
            throw new Error("FortuneManagerClient error");
         }
      }
      
      public static function getInstance() : FortuneManagerClient
      {
         if(_instance == null)
         {
            _instance = new FortuneManagerClient();
         }
         return _instance;
      }
      
      public function getStoreMessage() : void
      {
         this.sendMessage(cmdGetAccount,{});
      }
      
      public function takeAwayAccount(param1:int) : void
      {
         this.sendMessage(cmdTakeAwayAccount,{"ai":param1});
      }
      
      public function despositAccount(param1:int, param2:int, param3:int) : void
      {
         this.sendMessage(cmdDespositAccount,{
            "ai":param1,
            "sc":param2,
            "d":param3
         });
      }
      
      private function sendMessage(param1:String, param2:Object) : void
      {
         SocketClient.instance.sendXtMessage(this.extendsionName,param1,param2);
      }
   }
}

