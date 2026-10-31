package mmo.fbteam.fbsuolide.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene03.FBSuolide3_1Npc133Appear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene03.FBSuolide3_2MummyGame;
   import mmo.fbteam.fbsuolide.sceneplayer.scene03.FBSuolide3_3Leave;
   
   public class FBSuolideScenePlayer3 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide3";
      
      public function FBSuolideScenePlayer3()
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
            case FbSuolideCommandConst.FB3_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new FBSuolide3_1Npc133Appear();
               break;
            case FbSuolideCommandConst.FB3_SUOLIDE_5MUMMY_GAME:
               this.playerStep = new FBSuolide3_2MummyGame();
               break;
            case FbSuolideCommandConst.FB3_SUOLIDE_LEAVE:
               this.playerStep = new FBSuolide3_3Leave();
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

