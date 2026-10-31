package mmo.fbteam.fbaixi.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbaixi.FbAixiCommandConst;
   import mmo.fbteam.fbaixi.sceneplayer.scene8.FBAixi8_2FightWithBoss;
   import mmo.fbteam.fbaixi.sceneplayer.scene8.FBAixi8_3FightWinMovie;
   
   public class FBAixiScenePlayer8 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbaixi8";
      
      public function FBAixiScenePlayer8()
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
            case FbAixiCommandConst.FB8_2_BOSSINIT:
               this.playerStep = new FBAixi8_2FightWithBoss();
               break;
            case FbAixiCommandConst.FB8_3_WINMOVIE:
               this.playerStep = new FBAixi8_3FightWinMovie();
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

