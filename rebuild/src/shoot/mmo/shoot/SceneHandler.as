package mmo.shoot
{
   import flash.geom.Point;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.interfaces.shoot.effects.target.ShootForPoint;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   
   public class SceneHandler implements IShootTargetHandler
   {
      
      public static const targetName:String = "shoot_basescene";
      
      private var _targetInfo:TargetInfo;
      
      public function SceneHandler()
      {
         super();
         this._targetInfo = new TargetInfo(LayerManager.getBaseScene(),targetName,ShootTargetTypes.Null);
      }
      
      public function validateShoot() : Boolean
      {
         var _loc1_:Point = new Point(this._targetInfo.target.mouseX,this._targetInfo.target.mouseY);
         this._targetInfo.point = SceneManager.getInstance().loadedSceneInfo.scene.localPointToScene(_loc1_);
         return true;
      }
      
      public function validateHit(param1:ShootInfo) : Boolean
      {
         return true;
      }
      
      public function onBump(param1:ShootInfo, param2:Boolean) : IShootEffectTarget
      {
         return new ShootForPoint(param1.x,param1.y);
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

