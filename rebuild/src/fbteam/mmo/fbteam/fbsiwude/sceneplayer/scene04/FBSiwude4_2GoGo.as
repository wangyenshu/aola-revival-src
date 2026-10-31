package mmo.fbteam.fbsiwude.sceneplayer.scene04
{
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class FBSiwude4_2GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude4_2GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc4_:Sprite = ArrowHelper.getArrowhead(0);
         _loc4_.mouseChildren = false;
         _loc4_.mouseEnabled = false;
         _loc4_.x = 840;
         _loc4_.y = 220;
         this.sceneInfo.scene.foreGround.addChild(_loc4_);
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

