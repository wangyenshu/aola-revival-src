package mmo.fbservice.fbsuolide.fbsceneplayer.scene3
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   
   public class SuolidePlayer3_1Npc133Appear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var appear_landing:MovieClip = null;
      
      public function SuolidePlayer3_1Npc133Appear()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.npc113Appear();
      }
      
      private function npc113Appear() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Appear_landing") as Class;
         this.appear_landing = new _loc1_() as MovieClip;
         this.appear_landing.name = "appear_landing";
         this.addModalDialogMovieToScene(this.appear_landing,this.speak,204,391);
         this.appear_landing.gotoAndPlay(1);
      }
      
      private function speak() : void
      {
         this.appear_landing.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

