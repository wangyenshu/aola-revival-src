package mmo.fbteam.fbaixi.sceneplayer.scene4
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi4_6Road extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBAixi4_6Road()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         var _loc4_:MovieClip = this.getObstruction().getChildByName("move0") as MovieClip;
         DisplayUtil.stopAndRemove(_loc4_);
         SceneManager.getInstance().loadedSceneInfo.scene.setMapArray();
         this.movieFinish();
      }
      
      public function dispose() : void
      {
      }
   }
}

