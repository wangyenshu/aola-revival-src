package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene6.FBAixi6_1OpenLight;
   import mmo.fbteam.fbaixi.sceneplayer.scene6.FBAixi6_2OpenDoor;
   
   public class FBAixiScenePlayer6 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi6";
      
      public function FBAixiScenePlayer6()
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
            case FbAixiCommandConst.FB6_1_OPENLIGHT:
               this.playerStep = new FBAixi6_1OpenLight() as IScenePlayerStep;
               break;
            case FbAixiCommandConst.FB6_2_OPENDOOR:
               this.playerStep = new FBAixi6_2OpenDoor() as IScenePlayerStep;
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

