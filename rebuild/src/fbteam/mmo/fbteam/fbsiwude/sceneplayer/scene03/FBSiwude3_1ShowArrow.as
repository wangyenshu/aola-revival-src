package mmo.fbteam.fbsiwude.sceneplayer.scene03
{
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class FBSiwude3_1ShowArrow extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude3_1ShowArrow()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.showArrow();
         this.movieFinish(-1,param1);
      }
      
      private function showArrow() : void
      {
         var _loc1_:Sprite = ArrowHelper.getArrowhead(0);
         _loc1_.x = 800;
         _loc1_.y = 100;
         _loc1_.mouseChildren = false;
         _loc1_.mouseEnabled = false;
         _loc1_.name = "arrow";
         this.sceneInfo.scene.foreGround.addChild(_loc1_);
      }
      
      public function dispose() : void
      {
      }
   }
}

