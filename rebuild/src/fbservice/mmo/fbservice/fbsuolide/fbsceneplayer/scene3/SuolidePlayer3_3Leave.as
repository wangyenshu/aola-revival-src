package mmo.fbservice.fbsuolide.fbsceneplayer.scene3
{
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer3_3Leave extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      public function SuolidePlayer3_3Leave()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.leave();
      }
      
      private function leave() : void
      {
         SceneManager.getInstance().loadFB("fbsuolide4","fbsuolide");
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

