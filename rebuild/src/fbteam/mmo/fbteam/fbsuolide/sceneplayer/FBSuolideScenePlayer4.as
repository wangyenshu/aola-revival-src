package mmo.fbteam.fbsuolide.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene04.FBSuolide4_1Npc132Appear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene04.FBSuolide4_2FightAnubis;
   import mmo.fbteam.fbsuolide.sceneplayer.scene04.FBSuolide4_3Npc132Gift;
   
   public class FBSuolideScenePlayer4 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide4";
      
      public function FBSuolideScenePlayer4()
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
            case FbSuolideCommandConst.FB4_SUOLIDE_NPC132_APPEAR:
               this.playerStep = new FBSuolide4_1Npc132Appear();
               break;
            case FbSuolideCommandConst.FB4_FBSUOLIDE4_FIGHTWITHANUBIS:
               this.playerStep = new FBSuolide4_2FightAnubis();
               break;
            case FbSuolideCommandConst.FB4_SUOLIDE_NPC132_GIFT:
               this.playerStep = new FBSuolide4_3Npc132Gift();
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

