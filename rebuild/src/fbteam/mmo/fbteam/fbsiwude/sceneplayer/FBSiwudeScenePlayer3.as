package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene03.FBSiwude3_1ShowArrow;
   import mmo.fbteam.fbsiwude.sceneplayer.scene03.FBSiwude3_2Game;
   
   public class FBSiwudeScenePlayer3 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude3";
      
      public function FBSiwudeScenePlayer3()
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
            case FbSiwudeCommandConst.FB3_1SHOWARROW:
               this.playerStep = new FBSiwude3_1ShowArrow();
               break;
            case FbSiwudeCommandConst.FB3_2GAME:
               this.playerStep = new FBSiwude3_2Game();
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

