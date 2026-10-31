package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_1Npc16Come;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_2Npc132OutFromWall;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_3CallEnemy;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_4Npc132Disappear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_5Npc133Appear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene1.SuolidePlayer1_6GoGo;
   
   public class SuolideScenePlayer1 extends FBScenePlayerBase
   {
      
      private const sceneName:String = "fbsuolide1";
      
      public function SuolideScenePlayer1()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.disposeStepPlayer();
         if(!this.checkScene(this.sceneName))
         {
            return;
         }
         switch(param1)
         {
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC16_COME:
               this.playerStep = new SuolidePlayer1_1Npc16Come() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_OUT_FROM_WALL:
               this.playerStep = new SuolidePlayer1_2Npc132OutFromWall() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_CALL_ENEMY:
               this.playerStep = new SuolidePlayer1_3CallEnemy() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC132_DISAPPEAR:
               this.playerStep = new SuolidePlayer1_4Npc132Disappear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new SuolidePlayer1_5Npc133Appear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB1_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new SuolidePlayer1_6GoGo() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

