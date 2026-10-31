package mmo.game.parkour.data
{
   public class ParkourRewardInfo
   {
      
      private var _id:int;
      
      private var _senderId:int;
      
      private var _senderName:String;
      
      private var _title:String;
      
      private var _content:String;
      
      public function ParkourRewardInfo()
      {
         super();
      }
      
      public function parseParams(param1:Object) : void
      {
         this._id = param1.gId;
         this._senderId = param1.si;
         this._senderName = param1.sn;
         this._title = param1.ti;
         this._content = param1.ct;
      }
      
      public function get id() : int
      {
         return this._id;
      }
      
      public function get title() : String
      {
         return this._title;
      }
      
      public function get content() : String
      {
         return this._content;
      }
   }
}

