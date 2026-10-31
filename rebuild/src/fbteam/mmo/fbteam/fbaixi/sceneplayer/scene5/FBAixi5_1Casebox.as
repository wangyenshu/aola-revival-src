package mmo.fbteam.fbaixi.sceneplayer.scene5
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.ShootServiceEvent;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBAixi5_1Casebox extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const shootTargetName:String = "icebox";
      
      private var shootService:IShootService = null;
      
      private var fbTeamService:IFBTeamService = null;
      
      private var targetInfo:TargetInfo = null;
      
      private var mcBox:MovieClip = null;
      
      public function FBAixi5_1Casebox()
      {
         super();
         this.fbTeamService = ServiceContainer.getService(ServiceNames.FBTeamService) as IFBTeamService;
         this.shootService = ServiceContainer.getService(IShootService) as IShootService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.mcBox = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("moviebox") as MovieClip;
         TipsManager.getInstance().addTips(this.mcBox,"这个宝箱被冰封住了，可以用光能射线把冰融掉喔！");
         this.fbTeamService.addEventListener(FbEvent.ON_TRYGET_CASE,this.onGettedCase);
         this.shootInit();
      }
      
      private function shootInit() : void
      {
         var _loc1_:Point = new Point(682,281);
         this.targetInfo = new TargetInfo(this.mcBox,shootTargetName,ShootTargetTypes.Others,_loc1_);
         this.shootService.registerDefaultTarget(this.targetInfo);
         this.shootService.addEventListener(ShootServiceEvent.onBump,this.onShoot);
      }
      
      private function onShoot(param1:ShootServiceEvent) : void
      {
         var mc:MovieClip = null;
         var e:ShootServiceEvent = param1;
         var shootInfo:ShootInfo = e.params.shootInfo;
         if(e.params.targetInfo == this.targetInfo && shootInfo.cardId == 1)
         {
            TipsManager.getInstance().removeTips(this.mcBox);
            this.disposeShootEvent();
            mc = this.mcBox.getChildAt(0) as MovieClip;
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               mcBox.gotoAndStop(2);
               initClickAndHitEvent();
               DisplayUtil.stopAndRemove(mc);
            });
            mc.gotoAndPlay(2);
         }
      }
      
      private function initClickAndHitEvent() : void
      {
         this.mcBox.buttonMode = true;
         ClickAndHitHelper.instance.registerTarget(this.mcBox,true);
         this.mcBox.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickBox);
      }
      
      private function onClickBox(param1:ClickAndHitEvent) : void
      {
         this.disposeMCBoxEvent();
         this.fbTeamService.tryGetCurrentCase({});
      }
      
      private function onGettedCase(param1:FbEvent) : void
      {
         this.disposeEvents();
         this.mcBox.gotoAndStop(3);
         this.movieFinish();
      }
      
      private function disposeEvents() : void
      {
         this.disposeMCBoxEvent();
         this.disposeShootEvent();
         this.fbTeamService.removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGettedCase);
      }
      
      private function disposeMCBoxEvent() : void
      {
         this.mcBox.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickBox);
         this.mcBox.buttonMode = false;
         ClickAndHitHelper.instance.remove(this.mcBox);
      }
      
      private function disposeShootEvent() : void
      {
         this.shootService.removeEventListener(ShootServiceEvent.onBump,this.onShoot);
         this.shootService.removeTarget(ShootTargetTypes.Others,shootTargetName);
      }
      
      public function dispose() : void
      {
         this.disposeEvents();
      }
   }
}

