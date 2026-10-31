package mmo.fbteam.fbsuolide.sceneplayer.scene03
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide3_1Npc133Appear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var appear_landing:MovieClip = null;
      
      public function FBSuolide3_1Npc133Appear()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.npc113Appear();
      }
      
      private function npc113Appear() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Appear_landing") as Class;
         this.appear_landing = new _loc1_() as MovieClip;
         this.appear_landing.name = "appear_landing";
         this.addMovieToScene(this.appear_landing,this.speak,204,391);
         this.appear_landing.gotoAndPlay(1);
      }
      
      private function speak() : void
      {
         this.appear_landing.stop();
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

