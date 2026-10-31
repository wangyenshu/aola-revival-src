package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene2.FBAixi2_0CaptainScenario;
   import mmo.fbteam.fbaixi.sceneplayer.scene2.FBAixi2_0_1DarkShadow;
   import mmo.fbteam.fbaixi.sceneplayer.scene2.FBAixi2_1OpenDoor;
   
   public class FBAixiScenePlayer2 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi2";
      
      public function FBAixiScenePlayer2()
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
            case FbAixiCommandConst.FB2_0_1_ADDSHADOW:
               this.playerStep = new FBAixi2_0_1DarkShadow() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB2_0_CAPTAINSCENARIO:
               this.playerStep = new FBAixi2_0CaptainScenario() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB2_1_OPENDOOR:
               this.playerStep = new FBAixi2_1OpenDoor() as IScenePlayerStep;
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

