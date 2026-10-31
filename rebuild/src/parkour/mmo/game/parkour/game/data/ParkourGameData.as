package mmo.game.parkour.game.data
{
   import mmo.common.datastructure.ConfuseInteger;
   import mmo.game.parkour.game.config.ParkourGameConfig;
   
   public class ParkourGameData
   {
      
      private static const MaxMapSpeedOfMeter:int = -140;
      
      private var _mapSpeedMeter:ConfuseInteger = new ConfuseInteger(-70);
      
      private var _mapWidth:ConfuseInteger = new ConfuseInteger();
      
      private var _offestSpeed:ConfuseInteger = new ConfuseInteger();
      
      private var _logAddSpeedMeter:ConfuseInteger = new ConfuseInteger();
      
      private var _reliveTimes:ConfuseInteger = new ConfuseInteger();
      
      public function ParkourGameData()
      {
         super();
      }
      
      public function get mapWidth() : int
      {
         return this._mapWidth.getValue();
      }
      
      public function set mapWidth(param1:int) : void
      {
         this._mapWidth.setValue(param1);
      }
      
      public function get mapWidthMeter() : int
      {
         return this.mapWidth / ParkourGameConfig.MeterToPixel;
      }
      
      public function get mapSpeedOfFrame() : int
      {
         return this.mapSpeedMeter * ParkourGameConfig.MeterToPixel / ParkourGameConfig.FrameRate + this.offestSpeed;
      }
      
      public function get mapSpeedMeter() : int
      {
         return this._mapSpeedMeter.getValue();
      }
      
      public function set mapSpeedMeter(param1:int) : void
      {
         if(param1 <= MaxMapSpeedOfMeter)
         {
            this._mapSpeedMeter.setValue(MaxMapSpeedOfMeter);
         }
         else
         {
            this._mapSpeedMeter.setValue(param1);
         }
      }
      
      public function get offestSpeed() : int
      {
         return this._offestSpeed.getValue();
      }
      
      public function set offestSpeed(param1:int) : void
      {
         this._offestSpeed.setValue(param1);
      }
      
      public function get logAddSpeedMeter() : int
      {
         return this._logAddSpeedMeter.getValue();
      }
      
      public function set logAddSpeedMeter(param1:int) : void
      {
         this._logAddSpeedMeter.setValue(param1);
      }
      
      public function get reliveTimes() : int
      {
         return this._reliveTimes.getValue();
      }
      
      public function set reliveTimes(param1:int) : void
      {
         this._reliveTimes.setValue(param1);
      }
   }
}

