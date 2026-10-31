package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import mmo.fbteam.common.ScreenLock;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.draganddrop.DragAndDropHelper;
   
   public class FBSuolide8_6FindExit extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_6FindExit};
      
      private var zhang:MovieClip = null;
      
      private var stone:MovieClip = null;
      
      private var zhang2:MovieClip = null;
      
      private var exit:MovieClip = null;
      
      public function FBSuolide8_6FindExit()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setNotify(finishStep,this.sysData);
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
         var _loc3_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_zhang2") as Class;
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
         this.showExit();
      }
      
      private function showExit() : void
      {
         this.zhang2.removeEventListener(MouseEvent.CLICK,this.appear_exit);
         DisplayUtil.stopAndRemove(this.zhang2);
         DisplayUtil.stopAndRemove(this.stone);
         var _loc1_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone1");
         var _loc2_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone2");
         var _loc3_:DisplayObject = SceneManager.getInstance().loadedSceneInfo.scene.backGround.getChildByName("stone3");
         DisplayUtil.stopAndRemove(_loc1_);
         DisplayUtil.stopAndRemove(_loc2_);
         DisplayUtil.stopAndRemove(_loc3_);
         var _loc4_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_exit") as Class;
         this.exit = new _loc4_() as MovieClip;
         this.exit.addFrameScript(this.exit.totalFrames - 1,this.exit_end);
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.exit);
         if(TeamHelper.isCaptain())
         {
            ScreenLock.lock();
         }
         this.exit.gotoAndPlay(1);
      }
      
      private function exit_end() : void
      {
         if(TeamHelper.isCaptain())
         {
            ScreenLock.unlock();
         }
         this.exit.stop();
         this.notify(this.sysData);
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

