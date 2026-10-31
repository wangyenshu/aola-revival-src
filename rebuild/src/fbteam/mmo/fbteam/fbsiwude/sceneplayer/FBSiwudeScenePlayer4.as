package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene04.FBSiwude4_1Game;
   import mmo.fbteam.fbsiwude.sceneplayer.scene04.FBSiwude4_2GoGo;
   import mmo.fbteam.fbsiwude.sceneplayer.scene04.FBSiwude4_3GetBox;
   
   public class FBSiwudeScenePlayer4 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude4";
      
      public function FBSiwudeScenePlayer4()
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
            case FbSiwudeCommandConst.FB4_1GAME:
               this.playerStep = new FBSiwude4_1Game();
               break;
            case FbSiwudeCommandConst.FB4_2GOGO:
               this.playerStep = new FBSiwude4_2GoGo();
               break;
            case FbSiwudeCommandConst.FB4_3GETBOX:
               this.playerStep = new FBSiwude4_3GetBox();
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

