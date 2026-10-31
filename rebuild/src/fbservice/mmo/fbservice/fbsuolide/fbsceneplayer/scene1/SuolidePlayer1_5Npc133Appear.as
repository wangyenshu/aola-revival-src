package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   
   public class SuolidePlayer1_5Npc133Appear extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var lanDingAppear:MovieClip = null;
      
      public function SuolidePlayer1_5Npc133Appear()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playLanDingAppearMovie();
      }
      
      private function playLanDingAppearMovie() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.LanDingAppear") as Class;
         this.lanDingAppear = new _loc1_();
         this.lanDingAppear.name = "lanDingAppear";
         this.addModalDialogMovieToScene(this.lanDingAppear,this.lanDingAppearFinished,450,200);
      }
      
      private function lanDingAppearFinished() : void
      {
         this.lanDingAppear.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

