package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene7.FBAixi7_1Game;
   import mmo.fbteam.fbaixi.sceneplayer.scene7.FBAixi7_2OpenDoor;
   
   public class FBAixiScenePlayer7 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi7";
      
      public function FBAixiScenePlayer7()
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
            case FbAixiCommandConst.FB7_1_GAME:
               this.playerStep = new FBAixi7_1Game();
               break;
            case FbAixiCommandConst.FB7_2_OPENDOOR:
               this.playerStep = new FBAixi7_2OpenDoor();
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

