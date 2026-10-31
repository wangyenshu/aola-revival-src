package mmo.fbteam.fbsiwude.sceneplayer
{
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.fbteam.fbsiwude.sceneplayer.scene10.FBSiwude10_1Init;
   import mmo.fbteam.fbsiwude.sceneplayer.scene10.FBSiwude10_2Fight4;
   import mmo.fbteam.fbsiwude.sceneplayer.scene10.FBSiwude10_3DoorAndGogo;
   
   public class FBSiwudeScenePlayer10 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsiwude10";
      
      public function FBSiwudeScenePlayer10()
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
            case FbSiwudeCommandConst.FB10_1_INIT:
               this.playerStep = new FBSiwude10_1Init();
               break;
            case FbSiwudeCommandConst.FB10_2_FIGHT4:
               this.playerStep = new FBSiwude10_2Fight4();
               break;
            case FbSiwudeCommandConst.FB10_3_OPENDOORGOGO:
               this.playerStep = new FBSiwude10_3DoorAndGogo();
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

