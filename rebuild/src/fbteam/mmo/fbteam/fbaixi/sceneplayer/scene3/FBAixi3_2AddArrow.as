package mmo.fbteam.fbaixi.sceneplayer.scene3
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi3_2AddArrow extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBAixi3_2AddArrow()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.addMapArrow();
      }
      
      private function addMapArrow() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbaixi.FBAixi3_Arrow") as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(_loc2_);
      }
      
      public function dispose() : void
      {
      }
   }
}

