package mmo.fbteam.fbsuolide.sceneplayer
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBSuolideScenePlayer10 extends FBScenePlayerBase
   {
      
      private var soilPrince:MovieClip;
      
      private var cirrus:MovieClip;
      
      private var prince:MovieClip;
      
      private var prince2:MovieClip;
      
      private var princeHelpUs:MovieClip;
      
      private var pillar:MovieClip;
      
      public function FBSuolideScenePlayer10()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
      }
      
      override public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
         switch(param1)
         {
            case FbSuolideCommandConst.FB10_SUOLIDE_INIT_SCENE:
               this.initScene();
               break;
            case FbSuolideCommandConst.FB10_SUOLIDE_SAVE_PRINCE:
               this.savePrince();
               break;
            case FbSuolideCommandConst.FB10_SUOLIDE_PRINCEHELPUS:
               this.playPrinceHelpUs();
         }
      }
      
      private function initScene() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide10.SoilPrinceFallDown") as Class;
         this.soilPrince = new _loc1_();
         this.addMovieToScene(this.soilPrince,this.soilPrinceFinished);
      }
      
      private function soilPrinceFinished() : void
      {
         this.removeMovieFromScene(this.soilPrince);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide10.Cirrus") as Class;
         this.cirrus = new _loc1_() as MovieClip;
         this.cirrus.x = 350;
         this.cirrus.y = 250;
         this.cirrus.mouseChildren = false;
         this.cirrus.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.cirrus);
         this.cirrus.addEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
         this.cirrus.addEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsuolide10.SoilPrince") as Class;
         this.prince = new _loc1_();
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.prince);
         this.currentMovieFinish(-1,"fb10_suolide_init_scene");
      }
      
      private function onMouseDown(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         _loc2_.startDrag();
      }
      
      private function onMouseUp(param1:MouseEvent) : void
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         _loc2_.stopDrag();
         if(_loc2_.hitTestObject(this.prince))
         {
            _loc2_.removeEventListener(MouseEvent.MOUSE_DOWN,this.onMouseDown);
            _loc2_.removeEventListener(MouseEvent.MOUSE_UP,this.onMouseUp);
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.cirrus);
            this.currentMovieFinish(3,"577_fbsuolide10_afterSaveSoilPrince");
         }
         else
         {
            _loc2_.x = 350;
            _loc2_.y = 250;
         }
      }
      
      private function savePrince() : void
      {
      }
      
      private function playPrinceHelpUs() : void
      {
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.prince);
         var _loc1_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("pillar1") as MovieClip;
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(_loc1_);
         var _loc2_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide10.PrinceHelpUs") as Class;
         this.princeHelpUs = new _loc2_();
         this.addMovieToScene(this.princeHelpUs,this.princeHelpUsFinished);
      }
      
      private function princeHelpUsFinished() : void
      {
         this.removeMovieFromScene(this.princeHelpUs);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide10.Pillar") as Class;
         this.pillar = new _loc1_();
         this.pillar.x = 331;
         this.pillar.y = 297;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.pillar);
         this.removeObstruction();
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsuolide10.SoilPrince2") as Class;
         this.prince2 = new _loc1_();
         this.prince2.x = 823;
         this.prince2.y = 370;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.prince2);
         this.showWayOut();
      }
      
      private function showWayOut() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.task567.WayOut") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         _loc2_.x = 910;
         _loc2_.y = 360;
         _loc2_.scaleX = 2;
         _loc2_.scaleY = 2;
         TipsManager.getInstance().addTips(_loc2_,"离开倒立的金字塔");
         ClickAndHitHelper.instance.registerTarget(_loc2_,false,80);
         _loc2_.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onMouseClick);
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(_loc2_);
         _loc2_.alpha = 0.0003;
         _loc2_.buttonMode = true;
      }
      
      private function onMouseClick(param1:ClickAndHitEvent) : void
      {
         TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":577}));
         var _loc2_:IFBTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         _loc2_.finishFB(null);
      }
      
      private function removeObstruction() : void
      {
         var _loc1_:MovieClip = SceneManager.getInstance().loadedSceneInfo.scene.getChildByName("obstruction") as MovieClip;
         var _loc2_:MovieClip = _loc1_.getChildByName("mustDelete") as MovieClip;
         _loc1_.removeChild(_loc2_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
      }
      
      private function addMovieToScene(param1:MovieClip, param2:Function, param3:int = 0, param4:int = 0, param5:Boolean = false) : void
      {
         ModalDialogManager.getInstance().addModalDialog(param1,AlignType.NONE,PanelEffect.NONE,true,param3,param4);
         var _loc6_:int = param1.totalFrames;
         param1.addFrameScript(_loc6_ - 1,param2);
         param1.gotoAndPlay(1);
      }
      
      private function removeMovieFromScene(param1:MovieClip) : void
      {
         ModalDialogManager.getInstance().removeModalDialog(param1);
      }
      
      override public function dispose() : void
      {
      }
   }
}

