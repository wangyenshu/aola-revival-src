package mmo.game.parkour.game.player
{
   import mmo.common.datastructure.ConfuseInteger;
   
   public class ParkourPlayerParam
   {
      
      private var _totalScore:ConfuseInteger = new ConfuseInteger();
      
      private var _speedY:ConfuseInteger = new ConfuseInteger();
      
      private var _maxJumpTime:ConfuseInteger = new ConfuseInteger(2);
      
      private var _jumpTime:ConfuseInteger = new ConfuseInteger();
      
      private var _invincible:Boolean = false;
      
      private var _absorbing:Boolean = false;
      
      private var _power:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourPlayerParam()
      {
         super();
      }
      
      public function set absorbing(param1:Boolean) : void
      {
         this._absorbing = param1;
      }
      
      public function get absorbing() : Boolean
      {
         return this._absorbing;
      }
      
      public function get jumpTime() : int
      {
         return this._jumpTime.getValue();
      }
      
      public function set jumpTime(param1:int) : void
      {
         this._jumpTime.setValue(param1);
      }
      
      public function get speedY() : int
      {
         return this._speedY.getValue();
      }
      
      public function set speedY(param1:int) : void
      {
         this._speedY.setValue(param1);
      }
      
      public function get invincible() : Boolean
      {
         return this._invincible;
      }
      
      public function set invincible(param1:Boolean) : void
      {
         this._invincible = param1;
      }
      
      public function get maxJumpTime() : int
      {
         return this._maxJumpTime.getValue();
      }
      
      public function set maxJumpTime(param1:int) : void
      {
         this._maxJumpTime.setValue(param1);
      }
      
      public function get power() : int
      {
         return this._power.getValue();
      }
      
      public function set power(param1:int) : void
      {
         this._power.setValue(param1);
      }
      
      internal function get totalScore() : int
      {
         return this._totalScore.getValue();
      }
      
      internal function addTotalScore(param1:int) : void
      {
         this._totalScore.add(param1);
      }
   }
}

