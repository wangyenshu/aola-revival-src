package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene02.SiwudePlayer2_0Init;
   import mmo.fbteam.fbsiwude.sceneplayer.scene02.SiwudePlayer2_1ShowArrowhead;
   import mmo.fbteam.fbsiwude.sceneplayer.scene02.SiwudePlayer2_2Game;
   import mmo.fbteam.fbsiwude.sceneplayer.scene02.SiwudePlayer2_3Switch;
   
   public class FBSiwudeScenePlayer2 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude2";
      
      public function FBSiwudeScenePlayer2()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
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
            case FbSiwudeCommandConst.FB2_0_INIT:
               this.playerStep = new SiwudePlayer2_0Init();
               break;
            case FbSiwudeCommandConst.FB2_1_SHOW_ARROWHEAD:
               this.playerStep = new SiwudePlayer2_1ShowArrowhead() as IScenePlayerStep;
               break;
            case FbSiwudeCommandConst.FB2_2_GAME:
               this.playerStep = new SiwudePlayer2_2Game() as IScenePlayerStep;
               break;
            case FbSiwudeCommandConst.FB2_3_SWITCH:
               this.playerStep = new SiwudePlayer2_3Switch();
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

