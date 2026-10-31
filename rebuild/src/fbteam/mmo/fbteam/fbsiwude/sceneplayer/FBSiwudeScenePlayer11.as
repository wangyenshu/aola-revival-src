package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_1FourAttackMovie;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_2FightWithLittle;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_3FightWithBoss;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_4Aberrance;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_5FightWithAberrance;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_6AfterFightWinAberrance;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_7HelpQueen;
   import mmo.fbteam.fbsiwude.sceneplayer.scene11.FBSiwude11_8GetBonus;
   
   public class FBSiwudeScenePlayer11 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude11";
      
      public function FBSiwudeScenePlayer11()
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
            case FbSiwudeCommandConst.FB11_1_FOURATTACKMOVIE:
               this.playerStep = new FBSiwude11_1FourAttackMovie();
               break;
            case FbSiwudeCommandConst.FB11_2_FIGHTWITHLITTLE:
               this.playerStep = new FBSiwude11_2FightWithLittle();
               break;
            case FbSiwudeCommandConst.FB11_3_FIGHTWITHBOSS:
               this.playerStep = new FBSiwude11_3FightWithBoss();
               break;
            case FbSiwudeCommandConst.FB11_4_ABERRANCE:
               this.playerStep = new FBSiwude11_4Aberrance();
               break;
            case FbSiwudeCommandConst.FB11_5_FIGHTWITHABERRANCE:
               this.playerStep = new FBSiwude11_5FightWithAberrance();
               break;
            case FbSiwudeCommandConst.FB11_6_AFTERFIGHT:
               this.playerStep = new FBSiwude11_6AfterFightWinAberrance();
               break;
            case FbSiwudeCommandConst.FB11_7_HELPQUEUE:
               this.playerStep = new FBSiwude11_7HelpQueen();
               break;
            case FbSiwudeCommandConst.FB11_8_GETBONUS:
               this.playerStep = new FBSiwude11_8GetBonus();
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

