package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   
   public class SuolidePlayer8_3Npc133Appear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var appear_landing:MovieClip = null;
      
      public function SuolidePlayer8_3Npc133Appear()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playNpc133Appear();
      }
      
      private function getPars() : void
      {
      }
      
      private function playNpc133Appear() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_landing") as Class;
         this.appear_landing = new _loc1_() as MovieClip;
         this.appear_landing.name = "fb8_appear_landing";
         this.addModalDialogMovieToScene(this.appear_landing,this.landing_end,775,331);
      }
      
      private function landing_end() : void
      {
         this.appear_landing.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

