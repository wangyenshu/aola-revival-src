package mmo.fbteam.fbyishuzhidu.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbyishuzhidu.FbYishuzhiduCommandConst;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.YishuzhiduPlayer1_1Openlight;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.YishuzhiduPlayer1_2Dragon2real;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.YishuzhiduPlayer1_3Dragon2sham;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene1.YishuzhiduPlayer1_4OpenDoor;
   
   public class YishuzhiduScenePlayer1 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbyishuzhidu1";
      
      public function YishuzhiduScenePlayer1()
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
            case FbYishuzhiduCommandConst.FB1_1_OPENLIGHT:
               this.playerStep = new YishuzhiduPlayer1_1Openlight() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB1_2_DRAGON2REAL:
               this.playerStep = new YishuzhiduPlayer1_2Dragon2real() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB1_3_DRAGON2SHAM:
               this.playerStep = new YishuzhiduPlayer1_3Dragon2sham() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB1_4_OPENDOOR:
               this.playerStep = new YishuzhiduPlayer1_4OpenDoor() as IScenePlayerStep;
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

