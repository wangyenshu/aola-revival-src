package mmo.thinktower.interact
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.ShootServiceEvent;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.play.scene.SceneManager;
   
   public class ShootInteract implements Iinteract
   {
      
      private var shootservice:IShootService;
      
      private var fun:Function;
      
      private var params:Array;
      
      private var targetInfo:TargetInfo;
      
      public function ShootInteract()
      {
         super();
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         MovieClip(param1[0]).alpha = 0;
         this.shootservice = ServiceContainer.getService(IShootService) as IShootService;
         this.targetInfo = new TargetInfo(param1[0],param1[1],ShootTargetTypes.Others,new Point(MovieClip(param1[0]).x,MovieClip(param1[0]).y));
         TipsManager.getInstance().addTips(InteractiveObject(param1[0]),param1[3]);
         this.shootservice.registerDefaultTarget(this.targetInfo);
         this.shootservice.addEventListener(ShootServiceEvent.onBump,this.onShoot);
         this.fun = param2;
         this.params = param1;
      }
      
      private function onShoot(param1:ShootServiceEvent) : void
      {
         var _loc2_:TargetInfo = param1.params.targetInfo as TargetInfo;
         var _loc3_:ShootInfo = param1.params.shootInfo as ShootInfo;
         if(_loc2_ != this.targetInfo)
         {
            return;
         }
         if(_loc3_.from != SocketClient.instance.myUserName || _loc3_.cardId != this.params[2])
         {
            return;
         }
         this.shootservice.removeTarget(ShootTargetTypes.Others,this.params[1]);
         this.shootservice.removeEventListener(ShootServiceEvent.onBump,this.onShoot);
         var _loc4_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.obStruction;
         _loc4_.removeChild(_loc4_.getChildByName(this.params[1]));
         TipsManager.getInstance().removeTips(InteractiveObject(this.params[0]));
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.params[0]);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
         this.fun.apply(null,[this.params[0]]);
      }
      
      public function dispose() : void
      {
         if(this.shootservice != null)
         {
            this.shootservice.removeTarget(ShootTargetTypes.Others,this.params[1]);
            this.shootservice.removeEventListener(ShootServiceEvent.onBump,this.onShoot);
         }
         this.params = null;
      }
   }
}

