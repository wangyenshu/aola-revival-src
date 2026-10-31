package mmo.fbteam.fbsiwude.sceneplayer.scene10
{
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   
   public class FBSiwude10_1Init extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude10_1Init()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc4_:Sprite = this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite;
         _loc4_.y += 2000;
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

