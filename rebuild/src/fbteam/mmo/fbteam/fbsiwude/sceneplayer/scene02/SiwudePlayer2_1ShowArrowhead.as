package mmo.fbteam.fbsiwude.sceneplayer.scene02
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class SiwudePlayer2_1ShowArrowhead extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private const point:Point = new Point(820.2,176.5);
      
      public function SiwudePlayer2_1ShowArrowhead()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.showArrowMovie();
      }
      
      private function showArrowMovie() : void
      {
         var _loc1_:Sprite = ArrowHelper.getArrowhead(0);
         _loc1_.x = this.point.x;
         _loc1_.y = this.point.y;
         this.sceneInfo.scene.container.addChild(_loc1_);
         movieFinish(-1,type);
      }
      
      public function dispose() : void
      {
      }
   }
}

