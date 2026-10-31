package mmo.game.parkour.game.data.mapitem
{
   import mmo.common.datastructure.ConfuseInteger;
   
   public class ParkourMapItemInfo
   {
      
      private var _type:int;
      
      private var _score:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourMapItemInfo(param1:int, param2:int)
      {
         super();
         this._type = param1;
         this._score.setValue(param2);
      }
      
      public function get type() : int
      {
         return this._type;
      }
      
      public function get score() : int
      {
         return this._score.getValue();
      }
   }
}

