package mmo.activity130131.qiling
{
   public class QilingModal
   {
      
      public static const COLOR_RED:int = 0;
      
      public static const COLOR_BLUE:int = 1;
      
      public static const COLOR_GREEN:int = 2;
      
      public static const COLOR_STATE_NOT_PASS:int = 0;
      
      public static const COLOR_STATE_PASS:int = 1;
      
      public static const CHALLENGE_STATE_HAVENT_COLLECT_ALL:int = 0;
      
      public static const CHALLENGE_STATE_HAVENT_EXCHANGE:int = 1;
      
      public static const CHALLENGE_STATE_HAVENT_WIN:int = 2;
      
      public static const CHALLENGE_STATE_WIN:int = 3;
      
      public static const COLOR_NAMES:Array = ["红色","蓝色","绿色"];
      
      private var _curChallenge:int;
      
      private var _info:Array = [];
      
      public function QilingModal()
      {
         super();
      }
      
      public function getCurChallenge() : int
      {
         return this._curChallenge;
      }
      
      public function parseInfo(param1:String) : void
      {
         this._info = param1.split(":");
      }
      
      public function setCurChallenge(param1:int) : void
      {
         this._curChallenge = param1;
      }
      
      public function getAllColorState() : Array
      {
         return this._info.slice(0,this.getAllColor().length);
      }
      
      public function getColorState(param1:int) : int
      {
         return this._info[param1];
      }
      
      public function setChallengState(param1:int) : void
      {
         this._info[this.getAllColor().length] = param1;
      }
      
      public function setColorState(param1:int, param2:int) : void
      {
         this._info[param1] = param2;
      }
      
      public function getAllColor() : Array
      {
         return [COLOR_RED,COLOR_BLUE,COLOR_GREEN];
      }
      
      public function getChallengState() : int
      {
         return this._info[this.getAllColor().length];
      }
   }
}

