package mmo.messageboard.data
{
   public class MessageCache
   {
      
      private static var _instance:MessageCache;
      
      private var _totalNum:int;
      
      private var data:Array = new Array();
      
      public function MessageCache()
      {
         super();
         if(_instance != null)
         {
            throw new Error("MessageCache is implemented as Singleton!");
         }
      }
      
      public static function getInstance() : MessageCache
      {
         if(_instance == null)
         {
            _instance = new MessageCache();
         }
         return _instance;
      }
      
      public static function dispose() : void
      {
         _instance = null;
      }
      
      public function set totalNum(param1:int) : void
      {
         this._totalNum = param1;
      }
      
      public function get totalNum() : int
      {
         return this._totalNum;
      }
      
      public function updateMessage(param1:int, param2:int, param3:Array) : void
      {
         var _loc4_:int = param1;
         this.data.splice(_loc4_,param2);
         var _loc5_:int = 0;
         while(_loc5_ < param3.length)
         {
            if(!(param3[_loc5_] is MessageBoardData))
            {
               throw new Error("updateMessage must be MessageBoardData Object!");
            }
            this.data.splice(_loc4_,0,param3[_loc5_]);
            _loc4_++;
            _loc5_++;
         }
      }
      
      public function deleteMessage(param1:int) : void
      {
         this.data.splice(param1,1);
      }
      
      public function getMessage(param1:int, param2:int) : Array
      {
         return this.data.slice(param1,param1 + param2);
      }
   }
}

