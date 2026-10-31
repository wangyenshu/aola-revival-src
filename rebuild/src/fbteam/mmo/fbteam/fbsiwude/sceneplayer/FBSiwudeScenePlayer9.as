package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene09.FBSiwude9_1Init;
   import mmo.fbteam.fbsiwude.sceneplayer.scene09.FBSiwude9_2Game;
   import mmo.fbteam.fbsiwude.sceneplayer.scene09.FBSiwude9_3OpenDoor;
   import mmo.fbteam.fbsiwude.sceneplayer.scene09.FBSiwude9_4GoGo;
   
   public class FBSiwudeScenePlayer9 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude9";
      
      public function FBSiwudeScenePlayer9()
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
            case FbSiwudeCommandConst.FB9_1_INIT:
               this.playerStep = new FBSiwude9_1Init();
               break;
            case FbSiwudeCommandConst.FB9_2_GAME:
               this.playerStep = new FBSiwude9_2Game();
               break;
            case FbSiwudeCommandConst.FB9_3_OPENDOOR:
               this.playerStep = new FBSiwude9_3OpenDoor();
               break;
            case FbSiwudeCommandConst.FB9_4_GOGO:
               this.playerStep = new FBSiwude9_4GoGo();
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

