package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene05.SiwudePlayer5_0Init;
   import mmo.fbteam.fbsiwude.sceneplayer.scene05.SiwudePlayer5_1FightAnt;
   import mmo.fbteam.fbsiwude.sceneplayer.scene05.SiwudePlayer5_2GoGo;
   
   public class FBSiwudeScenePlayer5 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude5";
      
      public function FBSiwudeScenePlayer5()
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
            case FbSiwudeCommandConst.FB5_0_INIT:
               this.playerStep = new SiwudePlayer5_0Init();
               break;
            case FbSiwudeCommandConst.FB5_1_FIGHTANT:
               this.playerStep = new SiwudePlayer5_1FightAnt();
               break;
            case FbSiwudeCommandConst.FB5_2_GOGO:
               this.playerStep = new SiwudePlayer5_2GoGo();
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

