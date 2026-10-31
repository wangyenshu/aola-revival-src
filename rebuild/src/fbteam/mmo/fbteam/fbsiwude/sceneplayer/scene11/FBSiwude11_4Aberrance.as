package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.fbteam.configure.FBConfig;
   import mmo.interfaces.task.*;
   
   public class FBSiwude11_4Aberrance extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const showData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_4SHOWMOVIE};
      
      private var btnNpc:SimpleButton = null;
      
      private var Aberrance:MovieClip = null;
      
      private var general:SimpleButton = null;
      
      public function FBSiwude11_4Aberrance()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.btnNpc = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         this.btnNpc.addEventListener(MouseEvent.CLICK,this.onClick);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if(param1.params.action == "fbsiwude11_step6_end")
         {
            this.showTeamMovie();
         }
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.showTeamMovie();
      }
      
      private function showTeamMovie() : void
      {
         FBTeamSynchronizedClient.notify(this.showData);
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBSiwude_Scene11TempTypes.FBAIXI11_4SHOWMOVIE == param1.what)
         {
            this.showMovieAndRemoveEvent();
         }
      }
      
      private function showMovieAndRemoveEvent() : void
      {
         this.removeMovieTouchEvent();
         DisplayUtil.stopAndRemove(this.btnNpc);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.Aberrance") as Class;
         this.Aberrance = new _loc1_() as MovieClip;
         this.Aberrance.addFrameScript(this.Aberrance.totalFrames - 1,this.onAberranceFinished);
         ModalDialogManager.getInstance().addModalDialog(this.Aberrance,AlignType.NONE,PanelEffect.NONE,true,0,0);
         this.Aberrance.play();
      }
      
      private function removeMovieTouchEvent() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         this.btnNpc.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function onAberranceFinished() : void
      {
         this.Aberrance.stop();
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Fbsiwude11.AberranceGeneral") as Class;
         this.general = new _loc1_() as SimpleButton;
         this.general.x = 554;
         this.general.y = 213;
         this.general.name = "btn_general";
         this.sceneInfo.scene.container.addChild(this.general);
         ModalDialogManager.getInstance().removeModalDialog(this.Aberrance);
         this.movieFinish(-1,type);
      }
      
      public function dispose() : void
      {
         this.removeMovieTouchEvent();
      }
   }
}

