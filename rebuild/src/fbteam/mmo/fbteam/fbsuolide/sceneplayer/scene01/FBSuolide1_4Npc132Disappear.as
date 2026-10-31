package mmo.fbteam.fbsuolide.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide1_4Npc132Disappear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var anubisDisappear:MovieClip = null;
      
      private const sysData:Object = {"what":FBSuolide_Scene1TempTypes.FBSuolide1_4Npc132Disappear};
      
      public function FBSuolide1_4Npc132Disappear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playAnubisDisappearMovie,this.sysData,"fb_suolide1_talk_3_end");
      }
      
      private function playAnubisDisappearMovie() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.AnubisDisappear") as Class;
         this.anubisDisappear = new _loc1_();
         this.addMovieToScene(this.anubisDisappear,this.anubisDisappearFinished);
      }
      
      private function anubisDisappearFinished() : void
      {
         DisplayUtil.stopAndRemove(this.anubisDisappear);
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

