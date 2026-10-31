package mmo.fbteam.fbsiwude.sceneplayer.scene01
{
   import flash.display.Sprite;
   import flash.geom.Point;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.fbsiwude.sceneplayer.common.ArrowHelper;
   
   public class FBSiwude1_2ShowArrowhead extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const clsName:String = "mmo.scene.fbsiwude1.ShowArrowhead";
      
      private const point:Point = new Point(850,360);
      
      public function FBSiwude1_2ShowArrowhead()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         var _loc4_:Sprite = ArrowHelper.getArrowhead(0);
         _loc4_.x = this.point.x;
         _loc4_.y = this.point.y;
         this.sceneInfo.scene.container.addChild(_loc4_);
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

