package mmo.fbteam.fbaixi.sceneplayer.scene2
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   
   public class FBAixi2_0_1DarkShadow extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public static const NAME_DARKSHOADOW:String = "mc_darkshadow";
      
      public function FBAixi2_0_1DarkShadow()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.addDarkShadow();
         this.movieFinish();
      }
      
      private function addDarkShadow() : void
      {
         var _loc1_:SceneInfo = SceneManager.getInstance().loadedSceneInfo;
         var _loc2_:Class = _loc1_.applicationDomain.getDefinition("mmo.scene.fbaixi.Fbaixi2_DarkShadow") as Class;
         var _loc3_:MovieClip = new _loc2_() as MovieClip;
         _loc3_.stop();
         _loc3_.x = 480;
         _loc3_.y = 280;
         _loc3_.name = NAME_DARKSHOADOW;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc3_);
      }
      
      public function dispose() : void
      {
      }
   }
}

