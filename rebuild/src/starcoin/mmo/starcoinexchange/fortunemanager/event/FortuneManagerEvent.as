package mmo.starcoinexchange.fortunemanager.event
{
   import flash.events.Event;
   
   public class FortuneManagerEvent extends Event
   {
      
      public static var SHOW_PANEL:String = "SHOW_PANEL";
      
      private var _params:Object;
      
      public function FortuneManagerEvent(param1:String, param2:Object)
      {
         super(param1);
         this._params = param2;
      }
      
      public function get params() : Object
      {
         return this._params;
      }
   }
}

