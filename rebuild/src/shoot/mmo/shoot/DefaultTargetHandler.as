package mmo.shoot
{
   import flash.geom.Point;
   import mmo.common.user.UserInfo;
   import mmo.interfaces.shoot.IMoveableTarget;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.interfaces.shoot.effects.target.ShootForPoint;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   
   public class DefaultTargetHandler implements IShootTargetHandler
   {
      
      private var _targetInfo:TargetInfo;
      
      public function DefaultTargetHandler(param1:TargetInfo)
      {
         super();
         this._targetInfo = param1;
      }
      
      public function validateShoot() : Boolean
      {
         return true;
      }
      
      public function validateHit(param1:ShootInfo) : Boolean
      {
         return true;
      }
      
      public function onBump(param1:ShootInfo, param2:Boolean) : IShootEffectTarget
      {
         var _loc3_:Point = this.targetInfo.point;
         if(_loc3_ != null)
         {
            if(this.targetInfo.target is IMoveableTarget && param1.from != UserInfo.userName)
            {
               return new ShootForPoint(param1.x,param1.y);
            }
            return new ShootForPoint(_loc3_.x,_loc3_.y);
         }
         _loc3_ = new Point(param1.x,param1.y);
         return new ShootForPoint(_loc3_.x,_loc3_.y);
      }
      
      public function get targetInfo() : TargetInfo
      {
         return this._targetInfo;
      }
      
      public function refreshEffect(param1:Array, param2:int, param3:Array) : void
      {
      }
      
      public function dispose() : void
      {
         this._targetInfo = null;
      }
   }
}

