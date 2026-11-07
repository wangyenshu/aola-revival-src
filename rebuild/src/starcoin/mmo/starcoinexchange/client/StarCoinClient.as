package mmo.starcoinexchange.client
{
   import mmo.framework.comm.SocketClient;
   
   public class StarCoinClient
   {
      
      private static var _instance:StarCoinClient;
      
      private static var extensionName:String = "MaterialExtension";
      
      public static const cmdExchangeStarCoin:String = "14_19";
      
      public static const cmdAoToStarCoin:String = "14_20";
      
      public static const cmdGetAo:String = "14_21";
      
      public function StarCoinClient()
      {
         super();
      }
      
      public static function get instance() : StarCoinClient
      {
         if(_instance == null)
         {
            _instance = new StarCoinClient();
         }
         return _instance;
      }
      
      public function exchangeStarCoin(param1:int) : void
      {
         var _loc2_:Object = {"num":param1};
         this.sendXtMessage(cmdExchangeStarCoin,_loc2_);
      }
      
      public function aoToStarCoin(param1:int) : void
      {
         var _loc2_:Object = {"aobi":param1};
         this.sendXtMessage(cmdAoToStarCoin,_loc2_);
      }
      
      public function getAo() : void
      {
         this.sendXtMessage(cmdGetAo,{});
      }
      
      private function sendXtMessage(param1:String, param2:Object) : *
      {
         SocketClient.instance.sendXtMessage(extensionName,param1,param2);
      }
   }
}

