package mmo.game.parkour.data.ridepet
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRidePetAbility
   {
      
      private var _flyTime:ConfuseInteger = new ConfuseInteger();
      
      private var _flyCoinPercent:ConfuseInteger = new ConfuseInteger();
      
      private var _absoreTime:ConfuseInteger = new ConfuseInteger();
      
      private var _invincibleTime:ConfuseInteger = new ConfuseInteger();
      
      private var _scorePercent:ConfuseInteger = new ConfuseInteger();
      
      private var _moneyPercent:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourRidePetAbility(param1:int, param2:int, param3:int, param4:int, param5:int, param6:int)
      {
         super();
         this._flyTime.setValue(param1);
         this._flyCoinPercent.setValue(param2);
         this._absoreTime.setValue(param3);
         this._invincibleTime.setValue(param4);
         this._scorePercent.setValue(param5);
         this._moneyPercent.setValue(param6);
      }
      
      public function get flyCoinPercent() : int
      {
         return this._flyCoinPercent.getValue();
      }
      
      public function get flyTimeSec() : Number
      {
         return ParkourHelper.millSecToSec(this.flyTimeMillSec);
      }
      
      public function get absoreTimeSec() : Number
      {
         return ParkourHelper.millSecToSec(this.absoreTimeMillSec);
      }
      
      public function get invincibleTimeSec() : Number
      {
         return ParkourHelper.millSecToSec(this.invincibleTimeMillSec);
      }
      
      public function get flyTimeMillSec() : int
      {
         return this._flyTime.getValue();
      }
      
      public function get absoreTimeMillSec() : int
      {
         return this._absoreTime.getValue();
      }
      
      public function get invincibleTimeMillSec() : int
      {
         return this._invincibleTime.getValue();
      }
      
      public function get scorePercent() : Number
      {
         return this._scorePercent.getValue();
      }
      
      public function get moneyPercent() : Number
      {
         return this._moneyPercent.getValue();
      }
   }
}

