package mmo.fbteam.fbsuolide.sceneplayer
{
   import flash.display.MovieClip;
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_1MummyAppear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_2AndroidAppear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_3Npc133Appear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_4AndroidDestroy;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_5Npc133Disappear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_6FindExit;
   import mmo.fbteam.fbsuolide.sceneplayer.scene08.FBSuolide8_7ExitAppear;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolideScenePlayer8 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide8";
      
      private var stone:MovieClip;
      
      private var Coffin:MovieClip;
      
      public function FBSuolideScenePlayer8()
      {
         super();
      }
      
      override public function init() : void
      {
         this.gameInit();
      }
      
      private function gameInit() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_stone") as Class;
         this.stone = new _loc1_() as MovieClip;
         this.stone.x = 357;
         this.stone.y = 224;
         this.stone.name = "fb8_stone";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.stone);
         _loc1_ = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide8_coffin") as Class;
         this.Coffin = new _loc1_() as MovieClip;
         this.Coffin.x = 494.5;
         this.Coffin.y = 448.15;
         this.Coffin.name = "fbsuolide8_coffin";
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.Coffin);
      }
      
      override public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.disposeStepPlayer();
         if(!SceneHelper.checkScene(sceneName))
         {
            return;
         }
         this.type = param1;
         switch(param1)
         {
            case FbSuolideCommandConst.FB8_SUOLIDE_MUMMY_APPAER:
               this.playerStep = new FBSuolide8_1MummyAppear() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_ANDROID_APPEAR:
               this.playerStep = new FBSuolide8_2AndroidAppear() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new FBSuolide8_3Npc133Appear() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_ANDROID_DESTROY:
               this.playerStep = new FBSuolide8_4AndroidDestroy() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_NPC133_DISAPPEAR:
               this.playerStep = new FBSuolide8_5Npc133Disappear() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_FINDEXIT:
               this.playerStep = new FBSuolide8_6FindExit() as IScenePlayerStep;
               break;
            case FbSuolideCommandConst.FB8_SUOLIDE_EXIT_APPEAR:
               this.playerStep = new FBSuolide8_7ExitAppear() as IScenePlayerStep;
         }
         if(null != this.playerStep)
         {
            this.playerStep.run(param1,param2,param3);
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

