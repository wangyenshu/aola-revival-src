package mmo.fbteam.fbsiwude.sceneplayer.scene09
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class FBSiwude9_4GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude9_4GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc4_:Sprite = ArrowHelper.getArrowhead(0);
         _loc4_.x = 379.35;
         _loc4_.y = 98;
         this.sceneInfo.scene.container.addChild(_loc4_);
         (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y = (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y + 2000;
         this.moveRoadblock();
         this.movieFinish(-1,param1);
      }
      
      private function moveRoadblock() : void
      {
         var _loc1_:MovieClip = this.sceneInfo.scene.obStruction.getChildByName("roadblock") as MovieClip;
         DisplayUtil.stopAndRemove(_loc1_);
         this.sceneInfo.scene.setMapArray();
      }
      
      public function dispose() : void
      {
      }
   }
}

