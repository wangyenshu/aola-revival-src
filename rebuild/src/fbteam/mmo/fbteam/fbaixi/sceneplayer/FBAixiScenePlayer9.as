package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene9.FBAixi9_1BossAppear;
   import mmo.fbteam.fbaixi.sceneplayer.scene9.FBAixi9_2BossFight;
   import mmo.fbteam.fbaixi.sceneplayer.scene9.FBAixi9_3GetBonus;
   
   public class FBAixiScenePlayer9 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi9";
      
      public function FBAixiScenePlayer9()
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
            case FbAixiCommandConst.FB9_1_BOSSAPPEAR:
               this.playerStep = new FBAixi9_1BossAppear() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB9_2_BOSSFIGHT:
               this.playerStep = new FBAixi9_2BossFight() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB9_3_GETBONUS:
               this.playerStep = new FBAixi9_3GetBonus() as IScenePlayerStep;
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

