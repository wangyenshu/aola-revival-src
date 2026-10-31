package mmo.game.parkour.game.data.mapitem
{
   import mmo.common.datastructure.ConfuseInteger;
   
   public class ParkourPropInfo extends ParkourMapItemInfo
   {
      
      private var _minCreateMeter:ConfuseInteger = new ConfuseInteger();
      
      private var _createDelayMeter:ConfuseInteger = new ConfuseInteger();
      
      private var _effectClass:Class;
      
      private var _effectParams:Object;
      
      public function ParkourPropInfo(param1:int, param2:int, param3:int, param4:Class, param5:Object = null)
      {
         super(param1,0);
         this._minCreateMeter.setValue(param2);
         this._createDelayMeter.setValue(param3);
         this._effectClass = param4;
         this._effectParams = param5;
      }
      
      public function get effectParams() : Object
      {
         return this._effectParams;
      }
      
      public function get effectClass() : Class
      {
         return this._effectClass;
      }
      
      public function get createDelayMeter() : int
      {
         return this._createDelayMeter.getValue();
      }
      
      public function get minCreateMeter() : int
      {
         return this._minCreateMeter.getValue();
      }
   }
}

