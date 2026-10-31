package mmo.fbteam.fbyishuzhidu.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbyishuzhidu.FbYishuzhiduCommandConst;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.YishuzhiduPlayer4_1showArcher;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.YishuzhiduPlayer4_2fightArcher;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.YishuzhiduPlayer4_3showHistory;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene4.YishuzhiduPlayer4_4tryFinish;
   
   public class YishuzhiduScenePlayer4 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbyishuzhidu4";
      
      public function YishuzhiduScenePlayer4()
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
            case FbYishuzhiduCommandConst.FB4_1_SHOWARCHER:
               this.playerStep = new YishuzhiduPlayer4_1showArcher() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB4_2_FIGHTARCHER:
               this.playerStep = new YishuzhiduPlayer4_2fightArcher() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB4_3_TOXOPHILY_HISTORY:
               this.playerStep = new YishuzhiduPlayer4_3showHistory() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB4_4_TRYFINISH:
               this.playerStep = new YishuzhiduPlayer4_4tryFinish() as IScenePlayerStep;
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

