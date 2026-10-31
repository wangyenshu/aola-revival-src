package mmo.fbteam.fbsiwude.sceneplayer.scene10
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class FBSiwude10_3DoorAndGogo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const gogoPoint:Point = new Point(150,100);
      
      public function FBSiwude10_3DoorAndGogo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.removeHurdle();
         this.setExit();
         this.showGoGo();
         this.movieFinish(-1,param1);
      }
      
      private function showGoGo() : void
      {
         var _loc1_:Sprite = ArrowHelper.getArrowhead(35,false);
         _loc1_.mouseChildren = false;
         _loc1_.mouseEnabled = false;
         _loc1_.x = this.gogoPoint.x;
         _loc1_.y = this.gogoPoint.y;
         this.sceneInfo.scene.foreGround.addChild(_loc1_);
      }
      
      private function setExit() : void
      {
         var _loc1_:Sprite = this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite;
         _loc1_.y -= 2000;
      }
      
      private function removeHurdle() : void
      {
         var _loc1_:Sprite = this.getObstruction().getChildByName("hurdle") as Sprite;
         DisplayUtil.stopAndRemove(_loc1_);
         this.sceneInfo.scene.setMapArray();
      }
      
      public function dispose() : void
      {
      }
   }
}

