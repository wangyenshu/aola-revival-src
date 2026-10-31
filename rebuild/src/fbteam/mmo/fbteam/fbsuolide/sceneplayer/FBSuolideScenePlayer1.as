package mmo.fbteam.fbsuolide.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_1Npc16Come;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_2Npc132OutFromWall;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_3CallEnemy;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_4Npc132Disappear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_5Npc133Appear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene01.FBSuolide1_6GoGo;
   
   public class FBSuolideScenePlayer1 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide1";
      
      public function FBSuolideScenePlayer1()
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
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC16_COME:
               this.playerStep = new FBSuolide1_1Npc16Come();
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_OUT_FROM_WALL:
               this.playerStep = new FBSuolide1_2Npc132OutFromWall();
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_CALL_ENEMY:
               this.playerStep = new FBSuolide1_3CallEnemy();
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_DISAPPEAR:
               this.playerStep = new FBSuolide1_4Npc132Disappear();
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new FBSuolide1_5Npc133Appear();
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new FBSuolide1_6GoGo();
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

