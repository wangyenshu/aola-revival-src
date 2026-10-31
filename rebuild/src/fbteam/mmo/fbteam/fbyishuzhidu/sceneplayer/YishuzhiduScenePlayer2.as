package mmo.fbteam.fbyishuzhidu.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbyishuzhidu.FbYishuzhiduCommandConst;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene2.Scene2_1BackGround;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene2.Scene2_2Fight;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene2.Scene2_3Chips;
   import mmo.fbteam.fbyishuzhidu.sceneplayer.scene2.Scene2_4OpenDoor;
   
   public class YishuzhiduScenePlayer2 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbyishuzhidu2";
      
      public function YishuzhiduScenePlayer2()
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
            case FbYishuzhiduCommandConst.FB2_1_OPENBACKGROUND:
               this.playerStep = new Scene2_1BackGround() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB2_2_DRAGONFIGHT:
               this.playerStep = new Scene2_2Fight() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB2_3_CHIPSCOMM:
               this.playerStep = new Scene2_3Chips() as IScenePlayerStep;
               break;
            case FbYishuzhiduCommandConst.FB2_4_OPENDOOR:
               this.playerStep = new Scene2_4OpenDoor() as IScenePlayerStep;
               break;
            default:
               this.playerStep = null;
         }
         if(null != playerStep)
         {
            playerStep.run(param1,param2,param3);
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

