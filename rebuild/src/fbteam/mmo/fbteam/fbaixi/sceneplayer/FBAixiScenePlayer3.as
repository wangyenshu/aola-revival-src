package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene3.FBAixi3_1OpenDoor;
   import mmo.fbteam.fbaixi.sceneplayer.scene3.FBAixi3_2AddArrow;
   
   public class FBAixiScenePlayer3 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi3";
      
      public function FBAixiScenePlayer3()
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
            case FbAixiCommandConst.FB3_1_OPENDOOR:
               this.playerStep = new FBAixi3_1OpenDoor() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB3_2_ADDARROW:
               this.playerStep = new FBAixi3_2AddArrow() as IScenePlayerStep;
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

