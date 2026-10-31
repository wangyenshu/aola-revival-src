package mmo.fbteam.fbsiwude.sceneplayer.scene02
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   
   public class SiwudePlayer2_0Init extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      public function SiwudePlayer2_0Init()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc6_ = this.sceneInfo.scene.foreGround.getChildByName("light_" + _loc4_) as MovieClip;
            _loc6_.gotoAndStop(1);
            _loc7_ = this.sceneInfo.scene.foreGround.getChildByName("ant" + _loc4_) as MovieClip;
            _loc7_.gotoAndStop(1);
            _loc4_++;
         }
         var _loc5_:Sprite = this.sceneInfo.scene.foreGround.getChildByName("pit") as MovieClip;
         _loc5_.visible = false;
         this.movieFinish(-1,param1);
      }
      
      private function visibleLight(param1:String) : void
      {
         var _loc3_:Sprite = null;
         var _loc2_:int = 1;
         while(_loc2_ <= 3)
         {
            _loc3_ = this.sceneInfo.scene.foreGround.getChildByName(param1 + "_" + _loc2_) as Sprite;
            _loc3_.visible = false;
            _loc2_++;
         }
      }
      
      public function dispose() : void
      {
      }
   }
}

