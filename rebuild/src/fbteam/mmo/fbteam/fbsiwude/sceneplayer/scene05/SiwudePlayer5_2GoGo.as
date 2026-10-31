package mmo.fbteam.fbsiwude.sceneplayer.scene05
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   
   public class SiwudePlayer5_2GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var arrow:MovieClip;
      
      public function SiwudePlayer5_2GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc4_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.ShowArrowhead") as Class;
         this.arrow = new _loc4_() as MovieClip;
         this.sceneInfo.scene.container.addChild(this.arrow);
         this.arrow.x = 288.5;
         this.arrow.y = 93;
         (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y = (this.sceneInfo.scene.foreGround.getChildByName("et1") as Sprite).y + 500;
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

