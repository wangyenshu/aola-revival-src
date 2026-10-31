package mmo.fbservice.fbsuolide.fbsceneplayer.scene5
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   
   public class SuolidePlayer5_2GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var mc133appear:MovieClip = null;
      
      private var mcBalance:MovieClip = null;
      
      private var mcGo:MovieClip = null;
      
      private var mcYardL:MovieClip = null;
      
      private var mcYardR:MovieClip = null;
      
      private var btnReset:SimpleButton = null;
      
      private var obsBalance:Sprite = null;
      
      private var mcPoint1:Sprite = null;
      
      private var mcPoint2:Sprite = null;
      
      public function SuolidePlayer5_2GoGo()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.arrowheadChange();
      }
      
      private function arrowheadChange() : void
      {
         this.mc133appear = this.sceneInfo.scene.container.getChildByName("mc_133appear") as MovieClip;
         this.addMc133FrameScript();
         this.mc133appear.play();
      }
      
      private function addMc133FrameScript() : void
      {
         if(null != this.mc133appear)
         {
            this.mc133appear.addFrameScript(this.mc133appear.totalFrames - 1,function():void
            {
               mc133appear.stop();
               movieFinish(-1,this.type);
            });
         }
      }
      
      public function dispose() : void
      {
      }
   }
}

