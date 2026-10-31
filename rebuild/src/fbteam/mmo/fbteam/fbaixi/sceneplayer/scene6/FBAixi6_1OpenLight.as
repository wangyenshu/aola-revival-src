package mmo.fbteam.fbaixi.sceneplayer.scene6
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.play.scene.FBSceneBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBAixi6_1OpenLight extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var openLightData:Object = {
         "what":FBAixi_Scene6TempTypes.FBAIXI6_1OPENLIGHT,
         "framecount":1
      };
      
      private var blackScene:MovieClip;
      
      private var scene:FBSceneBase;
      
      private var frameCount:int = 1;
      
      public function FBAixi6_1OpenLight()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.init();
      }
      
      private function init() : void
      {
         this.scene = SceneManager.getInstance().loadedSceneInfo.scene as FBSceneBase;
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.BlackScene") as Class;
         this.blackScene = new _loc1_() as MovieClip;
         this.blackScene.mouseEnabled = false;
         this.blackScene.mouseChildren = false;
         this.blackScene.gotoAndStop(1);
         this.scene.foreGround.addChild(this.blackScene);
         var _loc2_:int = 1;
         while(_loc2_ <= 6)
         {
            MovieClip(this.scene.backGround.getChildByName("deng" + _loc2_)).buttonMode = true;
            _loc2_++;
         }
         var _loc3_:MovieClip = this.scene.backGround.getChildByName("deng1") as MovieClip;
         ClickAndHitHelper.instance.registerTarget(_loc3_,true,80);
         _loc3_.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickLight);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
      
      private function onClickLight(param1:ClickAndHitEvent) : void
      {
         var _loc2_:String = param1.currentTarget.name;
         var _loc3_:int = parseInt(_loc2_.slice(4));
         this.frameCount = _loc3_ + 1;
         this.openLightData.framecount = this.frameCount;
         FBTeamSynchronizedClient.notifyBack(this.openLightData);
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() != param1.teamKey)
         {
            return;
         }
         if(FBAixi_Scene6TempTypes.FBAIXI6_1OPENLIGHT == param1.what)
         {
            this.frameCount = param1.data.framecount;
            this.handleBlackScene();
         }
      }
      
      private function handleBlackScene() : void
      {
         var _loc1_:ITaskNpcService = null;
         var _loc2_:MovieClip = null;
         this.blackScene.gotoAndStop(this.frameCount);
         MovieClip(this.scene.backGround.getChildByName("deng" + (this.frameCount - 1))).removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickLight);
         ClickAndHitHelper.instance.remove(MovieClip(this.scene.backGround.getChildByName("deng" + (this.frameCount - 1))));
         if(this.frameCount == 7)
         {
            if(TeamHelper.isCaptain())
            {
               _loc1_ = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
               _loc1_.showNpcPanelFreely("fbaixi6_talk1",1);
            }
            DisplayUtil.stopAndRemove(this.blackScene);
            this.movieFinish();
         }
         else
         {
            _loc2_ = this.scene.backGround.getChildByName("deng" + this.frameCount) as MovieClip;
            ClickAndHitHelper.instance.registerTarget(_loc2_,true,80);
            _loc2_.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickLight);
         }
      }
      
      public function dispose() : void
      {
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
   }
}

