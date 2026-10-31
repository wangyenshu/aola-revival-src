package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.MovieClip;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_1MummyAppear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_2AndroidAppear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_3Npc133Appear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_4AndroidDestroy;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_5Npc133Disappear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_6FindExit;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene8.SuolidePlayer8_7ExitAppear;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.play.scene.SceneManager;
   
   public class SuolideScenePlayer8 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide8";
      
      private var stone:MovieClip;
      
      private var Coffin:MovieClip;
      
      public function SuolideScenePlayer8()
      {
         super();
      }
      
      override public function init() : void
      {
         this.gameInit();
      }
      
      private function gameInit() : void
      {
         var _loc1_:IFbService = ServiceContainer.getService(IFbService) as IFbService;
         _loc1_.addFollower(29999);
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_stone") as Class;
         this.stone = new _loc2_() as MovieClip;
         this.stone.x = 357;
         this.stone.y = 224;
         this.stone.name = "fb8_stone";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.stone);
         _loc2_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_coffin") as Class;
         this.Coffin = new _loc2_() as MovieClip;
         this.Coffin.x = 494.5;
         this.Coffin.y = 448.15;
         this.Coffin.name = "fbsuolide8_coffin";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.Coffin);
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.disposeStepPlayer();
         if(!this.checkScene(sceneName))
         {
            return;
         }
         switch(param1)
         {
            case FbSuolideCommandConst.FB8_SUOLIDE_MUMMY_APPAER:
               this.playerStep = new SuolidePlayer8_1MummyAppear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_ANDROID_APPEAR:
               this.playerStep = new SuolidePlayer8_2AndroidAppear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new SuolidePlayer8_3Npc133Appear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_ANDROID_DESTROY:
               this.playerStep = new SuolidePlayer8_4AndroidDestroy() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_NPC133_DISAPPEAR:
               this.playerStep = new SuolidePlayer8_5Npc133Disappear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_FINDEXIT:
               this.playerStep = new SuolidePlayer8_6FindExit() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_EXIT_APPEAR:
               this.playerStep = new SuolidePlayer8_7ExitAppear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

