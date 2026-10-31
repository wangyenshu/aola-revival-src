package mmo.fbservice.fbsuolide.fbsceneplayer.scene1
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer1_6GoGo extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var direct:MovieClip = null;
      
      private var lanDingAppear:MovieClip = null;
      
      public function SuolidePlayer1_6GoGo()
      {
         super();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playDirectMovie();
      }
      
      private function playDirectMovie() : void
      {
         var _loc1_:Sprite = LayerManager.getBaseTop().getChildByName("modalDialogContainer") as Sprite;
         this.lanDingAppear = _loc1_.getChildByName("lanDingAppear") as MovieClip;
         if(null != this.lanDingAppear)
         {
            ModalDialogManager.getInstance().removeModalDialog(this.lanDingAppear);
         }
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Direct") as Class;
         this.direct = new _loc2_();
         this.direct.x = 450;
         this.direct.y = 200;
         this.direct.addFrameScript(this.direct.totalFrames - 1,this.directFinished);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.direct);
      }
      
      private function directFinished() : void
      {
         this.direct.stop();
         this.direct.mouseChildren = false;
         this.direct.mouseEnabled = false;
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

