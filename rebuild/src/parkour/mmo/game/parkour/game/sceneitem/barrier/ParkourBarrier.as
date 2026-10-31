package mmo.game.parkour.game.sceneitem.barrier
{
   import flash.display.MovieClip;
   import mmo.game.parkour.game.data.mapitem.ParkourBarrierInfo;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourBarrier extends ParkourAbstractMapItem
   {
      
      private var _isDetroyed:Boolean = false;
      
      public function ParkourBarrier(param1:ParkourBarrierInfo, param2:MovieClip)
      {
         super(param1,param2);
      }
      
      public function destroy() : void
      {
         this._isDetroyed = true;
         signDispose();
      }
      
      override protected function onReset() : void
      {
         this._isDetroyed = false;
      }
      
      public function isDestroyed() : Boolean
      {
         return this._isDetroyed;
      }
      
      public function get canDestroy() : Boolean
      {
         return this.barrierInfo.canDestroy;
      }
      
      public function get barrierInfo() : ParkourBarrierInfo
      {
         return info as ParkourBarrierInfo;
      }
   }
}

