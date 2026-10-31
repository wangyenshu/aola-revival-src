package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamServiceEvent;
   
   public class FBSiwude11_7HelpQueen extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const showData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_7SHOWMOVIE};
      
      private const finishData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_7SHOWMOVIE_END};
      
      private var magicWater:MovieClip = null;
      
      private var key:MovieClip = null;
      
      private var teamService:ITeamService = null;
      
      private var finishCount:int = 0;
      
      public function FBSiwude11_7HelpQueen()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         this.key = this.sceneInfo.scene.backGround.getChildByName("key") as MovieClip;
         this.magicWater = this.sceneInfo.scene.backGround.getChildByName("magicWater") as MovieClip;
         this.teamService = ServiceContainer.getService(ITeamService) as ITeamService;
      }
      
      private function initFuns() : void
      {
         this.key.buttonMode = true;
         this.key.addEventListener(MouseEvent.CLICK,this.onClick);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.addEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         FBTeamSynchronizedClient.notify(this.showData);
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBSiwude_Scene11TempTypes.FBAIXI11_7SHOWMOVIE == param1.what)
         {
            this.showMovieAndRemoveTouchEvent();
         }
      }
      
      private function onFinishBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBSiwude_Scene11TempTypes.FBAIXI11_7SHOWMOVIE_END == param1.what)
         {
            ++this.finishCount;
            this.checkFinish();
         }
      }
      
      private function onMemberLeave(param1:TeamServiceEvent) : void
      {
         this.checkFinish();
      }
      
      private function showMovieAndRemoveTouchEvent() : void
      {
         this.removeTouchEvent();
         this.showUnlockMovie();
      }
      
      private function showUnlockMovie() : void
      {
         this.key.addFrameScript(this.key.totalFrames - 1,function():void
         {
            ModalDialogManager.getInstance().removeModalDialog(key);
            showHelpMovie();
         });
         this.key.gotoAndPlay(2);
         ModalDialogManager.getInstance().addModalDialog(this.key,AlignType.NONE);
      }
      
      private function showHelpMovie() : void
      {
         var cl:Class;
         var mc:MovieClip = null;
         DisplayUtil.stopAndRemove(this.magicWater);
         cl = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.HelpQueen") as Class;
         mc = new cl() as MovieClip;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            ModalDialogManager.getInstance().removeModalDialog(mc);
            addFatQueen();
            tryFinishStep();
         });
         ModalDialogManager.getInstance().addModalDialog(mc,AlignType.NONE,PanelEffect.NONE,true,0,0);
      }
      
      private function tryFinishStep() : void
      {
         FBTeamSynchronizedClient.finishBack(this.finishData);
      }
      
      private function checkFinish() : void
      {
         if(TeamHelper.checkCount(this.finishCount))
         {
            this.finishStep();
         }
      }
      
      private function addFatQueen() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.FatQueen") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         this.sceneInfo.scene.backGround.addChild(_loc2_);
      }
      
      private function removeTouchEvent() : void
      {
         this.key.mouseEnabled = false;
         this.key.removeEventListener(MouseEvent.CLICK,this.onClick);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function removeFinishEvnet() : void
      {
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdFinishBack,this.onFinishBack);
         this.teamService.removeEventListener(TeamServiceEvent.onMemberLeave,this.onMemberLeave);
      }
      
      public function dispose() : void
      {
         this.removeTouchEvent();
         this.removeFinishEvnet();
      }
   }
}

