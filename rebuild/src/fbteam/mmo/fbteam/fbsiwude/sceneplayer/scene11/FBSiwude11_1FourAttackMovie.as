package mmo.fbteam.fbsiwude.sceneplayer.scene11
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   
   public class FBSiwude11_1FourAttackMovie extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const showData:Object = {"what":FBSiwude_Scene11TempTypes.FBAIXI11_1SHOWMOVIE};
      
      private var mcFight:MovieClip = null;
      
      private var btnNpc:SimpleButton = null;
      
      public function FBSiwude11_1FourAttackMovie()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.mcFight = this.sceneInfo.scene.container.getChildByName("mc_fight") as MovieClip;
         this.mcFight.addEventListener(MouseEvent.CLICK,this.onClickFightMovie);
         this.btnNpc = this.sceneInfo.scene.container.getChildByName("btn_general") as SimpleButton;
         this.btnNpc.visible = false;
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if(param1.params.action == "fbsiwude11_step0_end")
         {
            this.showTeamMovie();
         }
      }
      
      private function onClickFightMovie(param1:MouseEvent) : void
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
         if(TeamHelper.getTeamKey() == param1.teamKey && FBSiwude_Scene11TempTypes.FBAIXI11_1SHOWMOVIE == param1.what)
         {
            this.showMovieAndRemoveTouchEvent();
         }
      }
      
      private function showMovieAndRemoveTouchEvent() : void
      {
         this.removeMovieTouchEvent();
         this.mcFight.addFrameScript(this.mcFight.totalFrames - 1,function():void
         {
            ModalDialogManager.getInstance().removeModalDialog(mcFight);
            btnNpc.visible = true;
            finishStep();
         });
         this.mcFight.gotoAndPlay(2);
         ModalDialogManager.getInstance().addModalDialog(this.mcFight,AlignType.NONE);
      }
      
      private function removeMovieTouchEvent() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.mcFight.removeEventListener(MouseEvent.CLICK,this.onClickFightMovie);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      public function dispose() : void
      {
         this.removeMovieTouchEvent();
      }
   }
}

