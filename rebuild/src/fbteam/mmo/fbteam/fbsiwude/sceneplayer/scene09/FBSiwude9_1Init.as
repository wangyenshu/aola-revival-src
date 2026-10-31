package mmo.fbteam.fbsiwude.sceneplayer.scene09
{
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   
   public class FBSiwude9_1Init extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude9_1Init()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y = (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y - 2000;
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

