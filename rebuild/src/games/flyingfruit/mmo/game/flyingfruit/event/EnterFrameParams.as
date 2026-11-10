package mmo.game.flyingfruit.event
{
   public class EnterFrameParams
   {
      
      private var _fun:Function;
      
      private var _interval:int;
      
      private var _params:Array;
      
      public function EnterFrameParams(param1:Function, param2:int, param3:Array)
      {
         super();
         this._fun = param1;
         this._interval = param2;
         this._params = param3;
      }
      
      public function get fun() : Function
      {
         return this._fun;
      }
      
      public function get interval() : int
      {
         return this._interval;
      }
      
      public function get params() : Array
      {
         return this._params;
      }
   }
}

