package mmo.fbteam.fbsiwude.sceneplayer.scene09
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   
   public class FBSiwude9_3OpenDoor extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var mcGate:MovieClip = null;
      
      public function FBSiwude9_3OpenDoor()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var type:String = param1;
         var callback:Function = param2;
         var args:Object = param3;
         this.type = type;
         this.mcGate = this.sceneInfo.scene.backGround.getChildByName("mc_gate") as MovieClip;
         this.mcGate.addFrameScript(this.mcGate.totalFrames - 1,function():void
         {
            mcGate.stop();
            movieFinish(-1,type);
         });
         this.mcGate.gotoAndPlay(2);
      }
      
      public function dispose() : void
      {
      }
   }
}

