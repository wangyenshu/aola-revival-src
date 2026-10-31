package mmo.fbteam.fbsuolide.sceneplayer.scene08
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide8_5Npc133Disappear extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene8TempTypes.FBSuolide8_5Npc133Disappear};
      
      private var landing2:MovieClip = null;
      
      private var falao2:MovieClip = null;
      
      private var zhang:MovieClip = null;
      
      public function FBSuolide8_5Npc133Disappear()
      {
         super();
         this.getPars();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.playNpc133Disappear,this.sysData,"fb_suolide8_talk_4_end");
      }
      
      private function getPars() : void
      {
      }
      
      private function playNpc133Disappear() : void
      {
         this.removeChildByName("fb8_appear_landing");
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_landing2") as Class;
         this.landing2 = new _loc1_() as MovieClip;
         this.landing2.addFrameScript(this.landing2.totalFrames - 1,this.landing_leave);
         this.landing2.x = 775;
         this.landing2.y = 331;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.landing2);
         this.landing2.gotoAndPlay(1);
      }
      
      private function landing_leave() : void
      {
         this.landing2.stop();
         this.removeChildByName("fb8_leave");
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_falao2") as Class;
         this.falao2 = new _loc1_() as MovieClip;
         this.falao2.x = 503;
         this.falao2.y = 288;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.falao2);
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_zhang") as Class;
         this.zhang = new _loc1_() as MovieClip;
         this.zhang.x = 425;
         this.zhang.y = 284;
         this.zhang.name = "fb8_zhang";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.zhang);
         this.finishStep();
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

