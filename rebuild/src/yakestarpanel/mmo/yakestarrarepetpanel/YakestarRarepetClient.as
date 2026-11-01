package mmo.yakestarrarepetpanel
{
   import mmo.framework.comm.SocketClient;
   
   public class YakestarRarepetClient
   {
      
      private static const extensionName:String = "PetExtension2";
      
      public static const cmdGetRarePetTime:String = "54e_23";
      
      public static const cmdLogRarePet:String = "54e_24";
      
      public function YakestarRarepetClient()
      {
         super();
      }
      
      public static function getRarePetTime() : void
      {
         sendXtMessage(cmdGetRarePetTime,{});
      }
      
      public static function logRarePet() : void
      {
         sendXtMessage(cmdLogRarePet,{});
      }
      
      private static function sendXtMessage(param1:String, param2:Object) : *
      {
         SocketClient.instance.sendXtMessage(extensionName,param1,param2);
      }
   }
}

