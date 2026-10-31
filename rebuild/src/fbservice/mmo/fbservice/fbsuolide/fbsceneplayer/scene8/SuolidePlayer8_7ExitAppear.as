package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class SuolidePlayer8_7ExitAppear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var exitsuolide8:MovieClip = null;
      
      public function SuolidePlayer8_7ExitAppear()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playExitAppear();
      }
      
      private function getPars() : void
      {
      }
      
      private function playExitAppear() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_exitsuolide8") as Class;
         this.exitsuolide8 = new _loc1_() as MovieClip;
         this.exitsuolide8.alpha = 0;
         this.exitsuolide8.x = 867;
         this.exitsuolide8.y = 161;
         this.exitsuolide8.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.exitsuolide8);
         ClickAndHitHelper.instance.registerTarget(this.exitsuolide8);
         this.exitsuolide8.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         TipsManager.getInstance().addTips(this.exitsuolide8,"通往下一场景");
         var _loc2_:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
         if(Boolean(_loc2_.isUserTaskDoing(567)) && Boolean(_loc2_.isUserTaskDoing(575)))
         {
            TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":575}));
         }
      }
      
      private function onHitExit(param1:ClickAndHitEvent) : void
      {
         this.exitsuolide8.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         this.movieFinish(-1,this.type);
         SceneManager.getInstance().loadFB("fbsuolide9","fbsuolide");
      }
      
      public function dispose() : void
      {
         if(this.exitsuolide8 != null)
         {
            ClickAndHitHelper.instance.remove(this.exitsuolide8);
            this.exitsuolide8.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         }
      }
   }
}

