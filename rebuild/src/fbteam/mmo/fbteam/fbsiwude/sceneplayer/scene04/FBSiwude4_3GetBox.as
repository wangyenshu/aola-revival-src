package mmo.fbteam.fbsiwude.sceneplayer.scene04
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBSiwude4_3GetBox extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var box:MovieClip = null;
      
      private var fbteamService:IFBTeamService = null;
      
      public function FBSiwude4_3GetBox()
      {
         super();
         this.fbteamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         this.box = this.sceneInfo.scene.backGround.getChildByName("treasure") as MovieClip;
      }
      
      private function initFuns() : void
      {
         ClickAndHitHelper.instance.registerTarget(this.box,true,40);
         this.box.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickBox);
         this.box.buttonMode = true;
         this.box.gotoAndStop(2);
         this.fbteamService.addEventListener(FbEvent.ON_TRYGET_CASE,this.onGettedCase);
      }
      
      private function onClickBox(param1:ClickAndHitEvent) : void
      {
         param1.stopImmediatePropagation();
         this.box.gotoAndStop(3);
         this.box.buttonMode = false;
         this.removeEvent();
         this.fbteamService.tryGetCurrentCase(null);
      }
      
      private function onGettedCase(param1:FbEvent) : void
      {
         this.fbteamService.removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGettedCase);
         this.removeEvent();
         this.movieFinish(-1,this.type);
      }
      
      private function removeEvent() : void
      {
         ClickAndHitHelper.instance.remove(this.box);
         this.box.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickBox);
      }
      
      public function dispose() : void
      {
         this.removeEvent();
         this.fbteamService.removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGettedCase);
      }
   }
}

