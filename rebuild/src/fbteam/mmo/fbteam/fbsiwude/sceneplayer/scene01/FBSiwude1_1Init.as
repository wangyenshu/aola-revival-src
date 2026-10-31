package mmo.fbteam.fbsiwude.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSiwude1_1Init extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function FBSiwude1_1Init()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         var _loc4_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.container;
         var _loc5_:Sprite = null;
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         while(_loc7_ < 3)
         {
            _loc6_ = _loc4_.getChildByName("ant" + _loc7_) as MovieClip;
            _loc6_.gotoAndStop(2);
            _loc5_ = _loc4_.getChildByName("area" + _loc7_) as Sprite;
            _loc5_.visible = false;
            _loc7_++;
         }
         _loc5_ = null;
         _loc6_ = null;
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
      }
   }
}

