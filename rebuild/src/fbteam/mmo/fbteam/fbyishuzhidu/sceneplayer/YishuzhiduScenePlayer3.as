package mmo.fbteam.fbyishuzhidu.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbyishuzhidu.FbYishuzhiduCommandConst;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene3.YishuzhiduPlayer3_1ClickGrass;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene3.YishuzhiduPlayer3_3FightDinosaur;
   
   public class YishuzhiduScenePlayer3 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbyishuzhidu3";
      
      public function YishuzhiduScenePlayer3()
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
            case FbYishuzhiduCommandConst.FB3_1_CLICKGRASS:
               this.playerStep = new YishuzhiduPlayer3_1ClickGrass() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB3_3_FIGHTDINOSAUR:
               this.playerStep = new YishuzhiduPlayer3_3FightDinosaur() as IScenePlayerStep;
               break;
            default:
               this.playerStep = null;
         }
         if(this.playerStep != null)
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

