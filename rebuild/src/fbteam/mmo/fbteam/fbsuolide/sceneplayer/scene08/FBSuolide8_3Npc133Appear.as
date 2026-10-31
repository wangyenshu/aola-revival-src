package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide8_3Npc133Appear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var appear_landing:MovieClip = null;
      
      public function FBSuolide8_3Npc133Appear()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.playNpc133Appear();
      }
      
      private function getPars() : void
      {
      }
      
      private function playNpc133Appear() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_landing") as Class;
         this.appear_landing = new _loc1_() as MovieClip;
         this.appear_landing.name = "fb8_appear_landing";
         this.addMovieToScene(this.appear_landing,this.landing_end,775,331);
      }
      
      private function landing_end() : void
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

