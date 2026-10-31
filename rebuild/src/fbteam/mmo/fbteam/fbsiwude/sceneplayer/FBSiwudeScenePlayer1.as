package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene01.FBSiwude1_1Init;
   import mmo.fbteam.fbsiwude.sceneplayer.scene01.FBSiwude1_2ShowArrowhead;
   import mmo.fbteam.fbsiwude.sceneplayer.scene01.FBSiwude1_3Game;
   
   public class FBSiwudeScenePlayer1 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude1";
      
      public function FBSiwudeScenePlayer1()
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
            case FbSiwudeCommandConst.FB1_1_INIT:
               this.playerStep = new FBSiwude1_1Init();
               break;
            case FbSiwudeCommandConst.FB1_2_SHOWARROWHEAD:
               this.playerStep = new FBSiwude1_2ShowArrowhead();
               break;
            case FbSiwudeCommandConst.FB1_3_GAME:
               this.playerStep = new FBSiwude1_3Game();
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

