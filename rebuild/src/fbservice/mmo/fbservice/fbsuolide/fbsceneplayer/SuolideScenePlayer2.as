package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene2.SuolidePlayer2_00StoneInfo;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene2.SuolidePlayer2_1GoGo;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene2.SuolidePlayer2_2Game;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   
   public class SuolideScenePlayer2 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide2";
      
      public function SuolideScenePlayer2()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.updataInfo(FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTONE_INFO,true);
         var _loc1_:IFbService = ServiceContainer.instance.getService(IFbService) as IFbService;
         var _loc2_:DisplayObject = _loc1_.addFollower(29999) as DisplayObject;
         _loc2_.name = "cat_follower";
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.disposeStepPlayer();
         if(!this.checkScene(sceneName))
         {
            return;
         }
         switch(param1)
         {
            case FbSuolideCommandConst.FB2_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new SuolidePlayer2_1GoGo() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTOME_GAME:
               this.playerStep = new SuolidePlayer2_2Game() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB2_SUOLIDE_FLAGSTONE_INFO:
               this.playerStep = new SuolidePlayer2_00StoneInfo() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

