package mmo.game.parkour.game.sceneitem.enemy
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.game.parkour.game.data.mapitem.ParkourEnemyInfo;
   import mmo.game.parkour.game.interfaces.IParkourMapItemMoveStrategy;
   import mmo.game.parkour.game.mapitem.ParkourAbstractMapItem;
   
   public class ParkourEnemy extends ParkourAbstractMapItem
   {
      
      private var _isDetroyed:Boolean = false;
      
      public function ParkourEnemy(param1:ParkourEnemyInfo, param2:MovieClip)
      {
         super(param1,param2);
         var _loc3_:int = Math.random() * param2.totalFrames + 1;
         param2.gotoAndStop(_loc3_);
         DisplayUtil.stop(param2);
      }
      
      override protected function setDefaultMove() : void
      {
         var _loc1_:Class = this.enemyInfo.moveClass;
         if(_loc1_ != null)
         {
            super.setMoveStrategy(new _loc1_() as IParkourMapItemMoveStrategy);
         }
         else
         {
            super.setDefaultMove();
         }
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
         return this.enemyInfo.canDestroy;
      }
      
      public function get enemyInfo() : ParkourEnemyInfo
      {
         return info as ParkourEnemyInfo;
      }
   }
}

