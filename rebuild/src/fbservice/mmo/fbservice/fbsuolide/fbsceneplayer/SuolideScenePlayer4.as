package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene4.SuolidePlayer4_1Npc132Appear;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene4.SuolidePlayer4_2FightAnubis;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene4.SuolidePlayer4_3Npc132Gift;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.task.ITaskNpcService;
   
   public class SuolideScenePlayer4 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide4";
      
      private var tasknpcServic:ITaskNpcService;
      
      private var anubisBecomeStone:MovieClip;
      
      private var anubisAppear:MovieClip;
      
      private var anubis:MovieClip = null;
      
      public function SuolideScenePlayer4()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         var _loc1_:IFbService = ServiceContainer.instance.getService(IFbService) as IFbService;
         var _loc2_:DisplayObject = _loc1_.addFollower(29999);
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
            case FbSuolideCommandConst.FB4_SUOLIDE_NPC132_APPEAR:
               this.playerStep = new SuolidePlayer4_1Npc132Appear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB4_FBSUOLIDE4_FIGHTWITHANUBIS:
               this.playerStep = new SuolidePlayer4_2FightAnubis() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB4_SUOLIDE_NPC132_GIFT:
               this.playerStep = new SuolidePlayer4_3Npc132Gift() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
         }
      }
      
      override public function dispose() : void
      {
         this.isClicking = false;
         this.tasknpcServic = null;
      }
   }
}

