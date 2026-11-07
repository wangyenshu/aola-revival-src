package mmo.messageboard.data
{
   public class MessageBoardData
   {
      
      private var _id:int;
      
      private var _type:int;
      
      private var _content:String;
      
      private var _userName:String;
      
      private var _nickName:String;
      
      private var _month:int;
      
      private var _day:int;
      
      public function MessageBoardData(param1:int, param2:int, param3:String, param4:String, param5:String, param6:int, param7:int)
      {
         super();
         this._id = param1;
         this._type = param2;
         this._content = param3;
         this._userName = param4;
         this._nickName = param5;
         this._month = param6;
         this._day = param7;
      }
      
      public function get id() : int
      {
         return this._id;
      }
      
      public function get type() : int
      {
         return this._type;
      }
      
      public function get content() : String
      {
         return this._content;
      }
      
      public function get userName() : String
      {
         return this._userName;
      }
      
      public function get nickName() : String
      {
         return this._nickName;
      }
      
      public function get month() : int
      {
         return this._month;
      }
      
      public function get day() : int
      {
         return this._day;
      }
   }
}

