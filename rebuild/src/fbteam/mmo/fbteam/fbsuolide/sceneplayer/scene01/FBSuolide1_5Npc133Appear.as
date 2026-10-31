package mmo.fbteam.fbsuolide.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide1_5Npc133Appear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var lanDingAppear:MovieClip = null;
      
      private const sysData:Object = {"what":FBSuolide_Scene1TempTypes.FBSuolide1_5Npc133Appear};
      
      public function FBSuolide1_5Npc133Appear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playLanDingAppearMovie,this.sysData,"fb_suolide1_talk_4_end");
      }
      
      private function playLanDingAppearMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.LanDingAppear") as Class;
         this.lanDingAppear = new _loc1_();
         this.lanDingAppear.name = "lanDingAppear";
         this.addMovieToScene(this.lanDingAppear,this.lanDingAppearFinished,450,200);
      }
      
      private function lanDingAppearFinished() : void
      {
         this.lanDingAppear.stop();
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

