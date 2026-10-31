package mmo.game.parkour.game.sceneitem.coin
{
   import flash.display.MovieClip;
   import mmo.game.parkour.game.data.mapitem.ParkourCoinInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourCoin extends ParkourAbstractMapItem
   {
      
      private var _isBeAbsorbing:Boolean;
      
      public function ParkourCoin(param1:ParkourCoinInfo, param2:MovieClip)
      {
         super(param1,param2);
      }
      
      override protected function onReset() : void
      {
         this.isBeAbsorbing = false;
      }
      
      public function get isBeAbsorbing() : Boolean
      {
         return this._isBeAbsorbing;
      }
      
      public function set isBeAbsorbing(param1:Boolean) : void
      {
         this._isBeAbsorbing = param1;
      }
      
      public function get score() : int
      {
         return this.coinInfo.score;
      }
      
      public function get coinInfo() : ParkourCoinInfo
      {
         return info as ParkourCoinInfo;
      }
   }
}

