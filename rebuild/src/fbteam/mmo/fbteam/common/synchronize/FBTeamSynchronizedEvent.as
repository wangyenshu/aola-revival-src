package mmo.fbteam.common.synchronize
{
   import flash.events.Event;
   
   public class FBTeamSynchronizedEvent extends Event
   {
      
      public static const cmdNotify:String = "synchronized_notify";
      
      public static const cmdNotifyBack:String = "synchronized_notify_back";
      
      public static const cmdFinishBack:String = "synchronized_finish_back";
      
      private var _data:Object = null;
      
      private var _teamKey:String = null;
      
      private var _what:String = null;
      
      private var _userName:String = null;
      
      public function FBTeamSynchronizedEvent(param1:String, param2:Object = null)
      {
         super(param1);
         this._data = param2;
         this._teamKey = this._data.teamkey;
         this._what = this._data.what;
         this._userName = this._data.un;
      }
      
      public function get data() : Object
      {
         return this._data;
      }
      
      public function get teamKey() : String
      {
         return this._teamKey;
      }
      
      public function get what() : String
      {
         return this._what;
      }
      
      public function get userName() : String
      {
         return this._userName;
      }
   }
}

