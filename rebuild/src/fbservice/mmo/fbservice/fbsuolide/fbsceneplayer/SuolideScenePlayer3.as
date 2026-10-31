package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene3.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.play.scene.SceneManager;
   
   public class SuolideScenePlayer3 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide3";
      
      public function SuolideScenePlayer3()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.initSceneInfo();
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
            case FbSuolideCommandConst.FB3_SUOLIDE_5MUMMY_GAME:
               this.playerStep = new SuolidePlayer3_2MummyGame() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB3_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new SuolidePlayer3_1Npc133Appear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB3_SUOLIDE_LEAVE:
               this.playerStep = new SuolidePlayer3_3Leave() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
         }
      }
      
      private function initSceneInfo() : void
      {
         var _loc5_:MovieClip = null;
         var _loc1_:IFbService = ServiceContainer.getService(IFbService) as IFbService;
         var _loc2_:DisplayObject = _loc1_.addFollower(29999);
         var _loc3_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Gai_suolide3") as Class;
         var _loc4_:* = 0;
         while(_loc4_ < 5)
         {
            _loc5_ = new _loc3_() as MovieClip;
            _loc5_.mouseChildren = false;
            _loc5_.x = 180.45 + 135 * _loc4_;
            _loc5_.y = 230.25;
            _loc5_.name = "coffin" + _loc4_.toString();
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc5_);
            _loc5_.stop();
            _loc4_++;
         }
      }
      
      override public function dispose() : void
      {
         this.disposeStepPlayer();
      }
   }
}

