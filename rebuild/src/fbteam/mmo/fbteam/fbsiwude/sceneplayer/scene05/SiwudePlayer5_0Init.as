package mmo.fbteam.fbsiwude.sceneplayer.scene05
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.configure.FBConfig;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneManager;
   
   public class SiwudePlayer5_0Init extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var scene:SceneBase;
      
      private var xyArray:Array = [[331.85,219.1],[393.85,210.1],[364.9,272.1],[427.3,260.1]];
      
      public function SiwudePlayer5_0Init()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc6_:SimpleButton = null;
         this.scene = SceneManager.getInstance().loadedSceneInfo.scene;
         var _loc4_:Class = FBConfig.instence.getClass("mmo.scene.fbsiwude.Ant") as Class;
         var _loc5_:int = 0;
         while(_loc5_ < this.xyArray.length)
         {
            _loc6_ = new _loc4_() as SimpleButton;
            _loc6_.name = "ant" + (_loc5_ + 1).toString();
            this.scene.container.addChild(_loc6_);
            _loc6_.x = this.xyArray[_loc5_][0];
            _loc6_.y = this.xyArray[_loc5_][1];
            _loc5_++;
         }
         (this.scene.foreGround.getChildByName("et1") as Sprite).y = (this.scene.foreGround.getChildByName("et1") as Sprite).y - 500;
         this.movieFinish(-1,param1);
      }
      
      public function dispose() : void
      {
         this.scene = null;
      }
   }
}

