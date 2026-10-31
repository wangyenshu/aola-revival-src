package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.sceneplayer.scene06.SiwudePlayer6_1Fight;
   import mmo.fbteam.fbsiwude.sceneplayer.scene06.SiwudePlayer6_2GoGo;
   
   public class FBSiwudeScenePlayer6 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude6";
      
      public function FBSiwudeScenePlayer6()
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
            case "fb6_1_fight":
               this.playerStep = new SiwudePlayer6_1Fight();
               break;
            case "fb6_2_GoGo":
               this.playerStep = new SiwudePlayer6_2GoGo();
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

