package mmo.game.parkour.common.rank
{
   public class ParkourRankInfo
   {
      
      private var _rank:int;
      
      private var _userName:String;
      
      private var _nickName:String;
      
      private var _score:int;
      
      public function ParkourRankInfo()
      {
         super();
      }
      
      public function parseParam(param1:Object) : void
      {
         this._userName = param1.dd;
         this._nickName = param1.nn;
         this._score = param1.md;
      }
      
      public function get userName() : String
      {
         return this._userName;
      }
      
      public function get nickName() : String
      {
         return this._nickName;
      }
      
      public function get score() : int
      {
         return this._score;
      }
      
      public function get rank() : int
      {
         return this._rank;
      }
      
      public function set rank(param1:int) : void
      {
         this._rank = param1;
      }
   }
}

