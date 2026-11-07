package mmo.activity130131.qiling
{
   import mmo.framework.comm.SocketClient;
   
   public class QilingClient
   {
      
      private static var _instance:QilingClient = null;
      
      private static const Extension:String = "HolidayExtension";
      
      private static const CmdHead:String = "0201qiling";
      
      public static const CmdInfo:String = CmdHead + "_panel";
      
      public static const CmdBuy:String = CmdHead + "_buy";
      
      public static const CmdExchange:String = CmdHead + "_exchange";
      
      public function QilingClient()
      {
         super();
      }
      
      public static function get instance() : QilingClient
      {
         if(_instance == null)
         {
            _instance = new QilingClient();
         }
         return _instance;
      }
      
      public function exchange() : void
      {
         SocketClient.instance.sendXtMessage(Extension,CmdExchange,null);
      }
      
      public function getInfo() : void
      {
         SocketClient.instance.sendXtMessage(Extension,CmdInfo,null);
      }
      
      public function buy(param1:int) : void
      {
         SocketClient.instance.sendXtMessage(Extension,CmdBuy,{"index":param1});
      }
   }
}

