package mmo.fbteam.fbsuolide.sceneplayer.scene05
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   
   public class FBSuolide5_2GoGo extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene5TempTypes.FBSuolide5_2GoGo};
      
      private var mc133appear:MovieClip = null;
      
      private var mcBalance:MovieClip = null;
      
      private var mcGo:MovieClip = null;
      
      private var mcYardL:MovieClip = null;
      
      private var mcYardR:MovieClip = null;
      
      private var btnReset:SimpleButton = null;
      
      private var obsBalance:Sprite = null;
      
      private var mcPoint1:Sprite = null;
      
      private var mcPoint2:Sprite = null;
      
      public function FBSuolide5_2GoGo()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.arrowheadChange,this.sysData,"fb_suolide5_talk_1_end");
      }
      
      private function arrowheadChange() : void
      {
         this.mc133appear = this.sceneInfo.scene.container.getChildByName("mc_133appear") as MovieClip;
         this.addMc133FrameScript();
         this.mc133appear.gotoAndPlay(this.mc133appear.currentFrame + 1);
      }
      
      private function addMc133FrameScript() : void
      {
         if(null != this.mc133appear)
         {
            this.mc133appear.addFrameScript(this.mc133appear.totalFrames - 1,function():void
            {
               mc133appear.stop();
               finishStep();
            });
         }
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

