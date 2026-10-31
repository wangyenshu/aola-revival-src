package mmo.fbteam.fbaixi.sceneplayer.scene7
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi7_2OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var et1:MovieClip = null;
      
      public function FBAixi7_2OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.et1 = SceneManager.getInstance().loadedSceneInfo.scene.foreGround.getChildByName("et1") as MovieClip;
         this.showOpenDoorMC();
      }
      
      private function showOpenDoorMC() : void
      {
         var mcDoor:MovieClip = null;
         mcDoor = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("door") as MovieClip;
         mcDoor.addFrameScript(mcDoor.totalFrames - 1,function():void
         {
            mcDoor.stop();
            et1.x -= 1000;
            movieFinish();
         });
         mcDoor.gotoAndPlay(2);
      }
      
      public function dispose() : void
      {
      }
   }
}

