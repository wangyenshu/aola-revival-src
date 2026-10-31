package mmo.fbteam.fbsuolide.sceneplayer.scene02
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide2_1GoGo extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      public function FBSuolide2_1GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.arrowheadChange();
      }
      
      private function arrowheadChange() : void
      {
         var fire:MovieClip = null;
         fire = this.sceneInfo.scene.backGround.getChildByName("mc_fire") as MovieClip;
         fire.addFrameScript(fire.totalFrames - 1,function():void
         {
            fire.stop();
            moveNext();
         });
         fire.gotoAndPlay(2);
      }
      
      private function moveNext() : void
      {
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

