package mmo.shoot.players
{
   import flash.geom.Point;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.shoot.ShootForPlayer;
   import mmo.shoot.players.effects.PlayerEffectManager;
   
   public class PlayerTargetHandler implements IShootTargetHandler
   {
      
      private var _targetInfo:TargetInfo;
      
      public function PlayerTargetHandler(param1:PlayerBase, param2:String)
      {
         super();
         this._targetInfo = new TargetInfo(param1,param2,ShootTargetTypes.Player);
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
         return new ShootForPlayer(PlayerBase(this.targetInfo.target));
      }
      
      public function get targetInfo() : TargetInfo
      {
         this._targetInfo.point = new Point(this._targetInfo.target.x,this._targetInfo.target.y);
         return this._targetInfo;
      }
      
      public function refreshEffect(param1:Array, param2:int, param3:Array) : void
      {
         var _loc5_:int = 0;
         var _loc4_:PlayerBase = this._targetInfo.target as PlayerBase;
         _loc4_ = PlayerManager.getInstance().playerList[_loc4_.getName()];
         if(_loc4_ == null)
         {
            return;
         }
         for each(_loc5_ in param3)
         {
            PlayerEffectManager.instance.clearEffect(_loc4_,_loc5_);
         }
         if(param2 != 0)
         {
            PlayerEffectManager.instance.applyEffect(_loc4_,param2);
         }
      }
      
      public function dispose() : void
      {
         this._targetInfo = null;
      }
   }
}

