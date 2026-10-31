package mmo.fbteam.fbaixi.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.userstate.IUserStateService;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi2_0CaptainScenario extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const showMovieData:Object = {"what":FBAixi_Scene2TempTypes.FBAIXI2_1SHOWMOVIE};
      
      private var boss:MovieClip = null;
      
      private var userStateService:IUserStateService = null;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var npcDarkShodaw:MovieClip = null;
      
      public function FBAixi2_0CaptainScenario()
      {
         super();
         this.userStateService = ServiceContainer.getService(IUserStateService) as IUserStateService;
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.npcDarkShodaw = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName(FBAixi2_0_1DarkShadow.NAME_DARKSHOADOW) as MovieClip;
         this.npcDarkShodaw.buttonMode = true;
         this.npcDarkShodaw.addEventListener(MouseEvent.CLICK,this.onClick);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.taskNpcService.showNpcPanelFreely("fbaixi2_talk1",601,1);
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         if(param1.params.action == "fbaixi2_talk1_end")
         {
            FBTeamSynchronizedClient.notify(this.showMovieData);
         }
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBAixi_Scene2TempTypes.FBAIXI2_1SHOWMOVIE == param1.what)
         {
            this.showMovie();
         }
      }
      
      private function showMovie() : void
      {
         this.npcDarkShodaw.addFrameScript(this.npcDarkShodaw.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(npcDarkShodaw);
            movieFinish();
         });
         this.npcDarkShodaw.gotoAndPlay(2);
      }
      
      public function dispose() : void
      {
         this.npcDarkShodaw.buttonMode = false;
         this.npcDarkShodaw.removeEventListener(MouseEvent.CLICK,this.onClick);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
      }
   }
}

