package mmo.fbteam.fbaixi.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi4_5OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const roadAppearedData:Object = {"what":FBAixi_Scene4TempTypes.FBAIXI4_5DOOROPENED};
      
      private var endCount:int = 0;
      
      public function FBAixi4_5OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
         this.showRoadAppearMovie();
      }
      
      private function showRoadAppearMovie() : void
      {
         var mc:MovieClip = null;
         var cls:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.RoadAppear") as Class;
         mc = new cls() as MovieClip;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            mc.stop();
            FBTeamSynchronizedClient.notifyBack(roadAppearedData);
         });
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(mc);
      }
      
      private function onNotifyBack(param1:FBTeamSynchronizedEvent) : void
      {
         if(TeamHelper.getTeamKey() == param1.teamKey && FBAixi_Scene4TempTypes.FBAIXI4_5DOOROPENED == param1.what)
         {
            this.endCountAdd();
         }
      }
      
      private function endCountAdd() : void
      {
         ++this.endCount;
         if(TeamHelper.checkCount(this.endCount))
         {
            this.movieFinish();
         }
      }
      
      public function dispose() : void
      {
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotifyBack,this.onNotifyBack);
      }
   }
}

