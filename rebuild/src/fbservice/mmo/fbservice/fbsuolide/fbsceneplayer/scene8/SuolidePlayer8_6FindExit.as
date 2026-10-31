package mmo.fbservice.fbsuolide.fbsceneplayer.scene8
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.draganddrop.DragAndDropHelper;
   
   public class SuolidePlayer8_6FindExit extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var zhang:MovieClip = null;
      
      private var stone:MovieClip = null;
      
      private var zhang2:MovieClip = null;
      
      private var exit:MovieClip = null;
      
      public function SuolidePlayer8_6FindExit()
      {
         super();
         this.getPars();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.playFindexit();
      }
      
      private function getPars() : void
      {
         this.zhang = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("fb8_zhang") as MovieClip;
         this.stone = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("fb8_stone") as MovieClip;
      }
      
      private function playFindexit() : void
      {
         DragAndDropHelper.instance.registerTarget(this.zhang,this.stone,this.hit,150,null,true);
      }
      
      private function hit(param1:Sprite, param2:Sprite) : void
      {
         var _loc3_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_zhang2") as Class;
         this.zhang2 = new _loc3_() as MovieClip;
         this.zhang2.x = 357;
         this.zhang2.y = 224;
         this.zhang2.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.zhang2);
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.stone);
         this.zhang2.addEventListener(MouseEvent.CLICK,this.appear_exit);
      }
      
      private function appear_exit(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.zhang2.removeEventListener(MouseEvent.CLICK,this.appear_exit);
         DisplayUtil.stopAndRemove(this.zhang2);
         DisplayUtil.stopAndRemove(this.stone);
         var _loc2_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone1");
         var _loc3_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone2");
         var _loc4_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone3");
         DisplayUtil.stopAndRemove(_loc2_);
         DisplayUtil.stopAndRemove(_loc3_);
         DisplayUtil.stopAndRemove(_loc4_);
         var _loc5_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_exit") as Class;
         this.exit = new _loc5_() as MovieClip;
         this.exit.addFrameScript(this.exit.totalFrames - 1,this.exit_end);
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.exit);
         Tool.instence.addTransparency();
         this.exit.gotoAndPlay(1);
      }
      
      private function exit_end() : void
      {
         Tool.instence.cleanTransparency();
         this.exit.stop();
         this.movieFinish(-1,this.type);
      }
      
      public function dispose() : void
      {
      }
   }
}

