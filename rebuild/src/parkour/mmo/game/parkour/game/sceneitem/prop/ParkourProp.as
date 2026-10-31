package mmo.game.parkour.game.sceneitem.prop
{
   import flash.display.MovieClip;
   import mmo.game.parkour.game.data.mapitem.ParkourPropInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourProp extends ParkourAbstractMapItem
   {
      
      private var _isAbsorbing:Boolean;
      
      public function ParkourProp(param1:ParkourPropInfo, param2:MovieClip)
      {
         super(param1,param2);
      }
      
      override protected function onReset() : void
      {
         this.isAbsorbing = false;
      }
      
      public function get isAbsorbing() : Boolean
      {
         return this._isAbsorbing;
      }
      
      public function set isAbsorbing(param1:Boolean) : void
      {
         this._isAbsorbing = param1;
      }
      
      public function get effectClass() : Class
      {
         return this.propInfo.effectClass;
      }
      
      public function get effectParams() : Object
      {
         return this.propInfo.effectParams;
      }
      
      public function get propInfo() : ParkourPropInfo
      {
         return info as ParkourPropInfo;
      }
   }
}

