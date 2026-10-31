package mmo.fbservice
{
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.loader.LoaderContainer;
   import mmo.play.player.movable.IMovable;
   import mmo.play.player.movable.strategy.AbstractMovingStrategy;
   
   public class PlayerFollowStrategy extends AbstractMovingStrategy
   {
      
      private var _target:IMovable;
      
      private var _arrivedToTarget:Boolean = false;
      
      private var _destX:Number;
      
      private var _destY:Number;
      
      public function PlayerFollowStrategy(param1:IMovable)
      {
         super();
         this._target = param1;
      }
      
      override public function setControlItem(param1:IMovable) : void
      {
         super.setControlItem(param1);
         this.follow();
      }
      
      override public function dispose() : void
      {
         this.unfollow();
         this._target = null;
         super.dispose();
      }
      
      private function follow() : void
      {
         LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,this.onEnterFrame);
      }
      
      private function unfollow() : void
      {
         LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
      }
      
      private function onEnterFrame(param1:Event) : void
      {
         var _loc2_:Number = this.getDistance(new Point(this._controlItem.x,this._controlItem.y),new Point(this._target.x,this._target.y));
         if(_loc2_ < 50)
         {
            if(!this._target.isMoving() && Boolean(this._controlItem.isMoving()))
            {
               this._controlItem.stop();
            }
            if(!this._arrivedToTarget)
            {
               this._arrivedToTarget = true;
            }
            return;
         }
         if(this._arrivedToTarget)
         {
            this.moveToTargetDest();
         }
         else
         {
            this.moveToTarget();
         }
      }
      
      private function moveToTarget() : void
      {
         this._destX = this._target.x;
         this._destY = this._target.y;
         this._controlItem.moveTo(this._destX,this._destY,this._target.walkSpeed);
      }
      
      private function moveToTargetDest() : void
      {
         if(this._destX == this._target.destX && this._destY == this._target.destY)
         {
            return;
         }
         this._destX = this._target.destX;
         this._destY = this._target.destY;
         this._controlItem.moveTo(this._destX,this._destY,this._target.walkSpeed);
      }
      
      private function getDistance(param1:Point, param2:Point) : Number
      {
         var _loc3_:Number = Math.pow(param1.x - param2.x,2) + Math.pow(param1.y - param2.y,2);
         return Math.sqrt(_loc3_);
      }
   }
}

