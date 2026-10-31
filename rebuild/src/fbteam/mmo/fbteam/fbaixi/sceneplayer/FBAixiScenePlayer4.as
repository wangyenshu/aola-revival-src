package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene4.FBAixi4_1BossAppear;
   import mmo.fbteam.fbaixi.sceneplayer.scene4.FBAixi4_3BossFight;
   import mmo.fbteam.fbaixi.sceneplayer.scene4.FBAixi4_4BossDisappear;
   import mmo.fbteam.fbaixi.sceneplayer.scene4.FBAixi4_5OpenDoor;
   import mmo.fbteam.fbaixi.sceneplayer.scene4.FBAixi4_6Road;
   
   public class FBAixiScenePlayer4 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi4";
      
      public function FBAixiScenePlayer4()
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
            case FbAixiCommandConst.FB4_1_BOSSAPPEAR:
               this.playerStep = new FBAixi4_1BossAppear() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB4_3_BOSSFIGHT:
               this.playerStep = new FBAixi4_3BossFight() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB4_4_BOSSDISAPPEAR:
               this.playerStep = new FBAixi4_4BossDisappear() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB4_5_OPENDOOR:
               this.playerStep = new FBAixi4_5OpenDoor() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB4_6_ROAD:
               this.playerStep = new FBAixi4_6Road() as IScenePlayerStep;
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

