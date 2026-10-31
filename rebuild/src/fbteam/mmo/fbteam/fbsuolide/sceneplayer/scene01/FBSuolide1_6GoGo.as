package mmo.fbteam.fbsuolide.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide1_6GoGo extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var direct:MovieClip = null;
      
      private var lanDingAppear:MovieClip = null;
      
      private const sysData:Object = {"what":FBSuolide_Scene1TempTypes.FBSuolide1_6GoGo};
      
      public function FBSuolide1_6GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playDirectMovie,this.sysData,"fb_suolide1_talk_5_end");
      }
      
      private function playDirectMovie() : void
      {
         this.removeChildByName("lanDingAppear");
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Direct") as Class;
         this.direct = new _loc1_();
         this.direct.x = 450;
         this.direct.y = 200;
         this.direct.addFrameScript(this.direct.totalFrames - 1,this.directFinished);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.direct);
      }
      
      private function directFinished() : void
      {
         this.direct.stop();
         this.direct.mouseChildren = false;
         this.direct.mouseEnabled = false;
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

