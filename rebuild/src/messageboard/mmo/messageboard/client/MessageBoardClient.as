package mmo.messageboard.client
{
   import mmo.framework.comm.SocketClient;
   
   public class MessageBoardClient
   {
      
      private static var _instance:MessageBoardClient;
      
      public static const cmdModifiMyMessage:* = "62_11";
      
      public static const cmdGetFirstPage:String = "62_12";
      
      public static const cmdGetPage:String = "62_13";
      
      public static const cmdLeaveMsg:String = "62_14";
      
      public static const cmdDelMsg:String = "62_15";
      
      public static const cmdReportMsg:String = "62_16";
      
      private const extendsName:String = "HouseExtension";
      
      public function MessageBoardClient()
      {
         super();
         if(_instance != null)
         {
            throw new Error("MessageBoardClient is implemented as Singleton!");
         }
      }
      
      public static function getInstance() : MessageBoardClient
      {
         if(_instance == null)
         {
            _instance = new MessageBoardClient();
         }
         return _instance;
      }
      
      private static function dispose() : void
      {
         _instance = null;
      }
      
      public function modifiMyMessage(param1:String) : void
      {
         this.sendMessage(cmdModifiMyMessage,{"msg":param1});
      }
      
      public function getFirstPageMessage(param1:String) : void
      {
         this.sendMessage(cmdGetFirstPage,{"un":param1});
      }
      
      public function getPageMessage(param1:String, param2:int) : void
      {
         this.sendMessage(cmdGetPage,{
            "un":param1,
            "page":param2
         });
      }
      
      public function leaveMessage(param1:String, param2:String, param3:int) : void
      {
         this.sendMessage(cmdLeaveMsg,{
            "un":param1,
            "content":param2,
            "type":param3
         });
      }
      
      public function deleteMessage(param1:int) : void
      {
         this.sendMessage(cmdDelMsg,{"id":param1});
      }
      
      public function reportMessage(param1:String, param2:int) : void
      {
         this.sendMessage(cmdReportMsg,{
            "un":param1,
            "id":param2
         });
      }
      
      private function sendMessage(param1:String, param2:Object) : void
      {
         SocketClient.instance.sendXtMessage(this.extendsName,param1,param2);
      }
   }
}

