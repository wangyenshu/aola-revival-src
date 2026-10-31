package mmo.fbteam.fbsuolide.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene02.FBSuolide2_0StoneInfo;
   import mmo.fbteam.fbsuolide.sceneplayer.scene02.FBSuolide2_1GoGo;
   import mmo.fbteam.fbsuolide.sceneplayer.scene02.FBSuolide2_2Game;
   
   public class FBSuolideScenePlayer2 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide2";
      
      public function FBSuolideScenePlayer2()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.updataInfo(FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTONE_INFO);
      }
      
      override public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.disposeStepPlayer();
         if(!SceneHelper.checkScene(sceneName))
         {
            return;
         }
         switch(param1)
         {
            case FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTONE_INFO:
               this.playerStep = new FBSuolide2_0StoneInfo();
               break;
            case FbSuolideCommandConst.FB2_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new FBSuolide2_1GoGo();
               break;
            case FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTOME_GAME:
               this.playerStep = new FBSuolide2_2Game();
               break;
            default:
               this.playerStep = null;
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

