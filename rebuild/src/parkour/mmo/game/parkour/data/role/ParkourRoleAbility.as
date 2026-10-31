package mmo.game.parkour.data.role
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourRoleAbility
   {
      
      private var _flyTime:ConfuseInteger = new ConfuseInteger();
      
      private var _flyCoinPercent:ConfuseInteger = new ConfuseInteger();
      
      private var _absoreTime:ConfuseInteger = new ConfuseInteger();
      
      private var _invincibleTime:ConfuseInteger = new ConfuseInteger();
      
      private var _superCool:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourRoleAbility(param1:int, param2:int, param3:int, param4:int, param5:int)
      {
         super();
         this._flyTime.setValue(param1);
         this._flyCoinPercent.setValue(param2);
         this._absoreTime.setValue(param3);
         this._invincibleTime.setValue(param4);
         this._superCool.setValue(param5);
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
      
      public function get superCool() : int
      {
         return this._superCool.getValue();
      }
   }
}

