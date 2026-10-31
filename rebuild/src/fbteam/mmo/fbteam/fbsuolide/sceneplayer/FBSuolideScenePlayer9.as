package mmo.fbteam.fbsuolide.sceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.FBScenePlayerBase;
   import mmo.fbteam.common.FBCommonHelper;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedClient;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEvent;
   import mmo.fbteam.common.synchronize.FBTeamSynchronizedEventDispatcher;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   
   public class FBSuolideScenePlayer9 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide9";
      
      private var sysData:Object = {"what":"9"};
      
      private var what:String = "9";
      
      private var appearfalao:MovieClip;
      
      private var coffin_open:MovieClip;
      
      private var falao:MovieClip;
      
      private var landing_appear:MovieClip;
      
      private var landing_disappear:MovieClip;
      
      private var coffin:MovieClip;
      
      private var petid:int = 1;
      
      private var fbservice:IFBTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
      
      private var stoneMC:MovieClip;
      
      private var coffin_open_state:MovieClip;
      
      private var exitsuolide9:MovieClip;
      
      private var cat_disappear:MovieClip;
      
      private var taskService:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
      
      private var fire:MovieClip;
      
      private var taskNpcService:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      
      private var funs:Array = [];
      
      private var pushStr:Array = [];
      
      public function FBSuolideScenePlayer9()
      {
         super();
      }
      
      override public function init() : void
      {
         this.gameInit();
      }
      
      private function gameInit() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_coffin") as Class;
         this.coffin = new _loc1_() as MovieClip;
         this.coffin.x = 462.6;
         this.coffin.y = 339;
         this.funs = [this.npc133_appear,this.fight_win,this.cat_appear];
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.coffin);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         FBTeamSynchronizedEventDispatcher.instance.addEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
      }
      
      private function onNotify(param1:FBTeamSynchronizedEvent) : void
      {
         var _loc2_:String = null;
         if(TeamHelper.getTeamKey() == param1.teamKey && param1.what == this.what)
         {
            _loc2_ = param1.data.step + param1.data.info;
            if(this.pushStr.indexOf(_loc2_) != -1)
            {
               return;
            }
            this.pushStr.push(_loc2_);
            if(param1.data.info == "#")
            {
               this.funs[param1.data.step].apply();
            }
            else
            {
               this.currentMovieFinish(param1.data.step,param1.data.info);
            }
         }
      }
      
      private function notify(param1:int, param2:String) : void
      {
         FBTeamSynchronizedClient.notify({
            "what":this.what,
            "step":param1,
            "info":param2
         });
      }
      
      private function onAction(param1:TaskEvent) : void
      {
         switch(param1.params.action)
         {
            case "fb_suolide9_talk_1_end":
               this.fightwith();
               break;
            case "fb_suolide9_talk_2_end":
               this.notify(0,"#");
               break;
            case "fb_suolide9_talk_3_end":
               this.notify(1,"#");
               break;
            case "fb_suolide9_talk_4_end":
               this.present();
         }
      }
      
      override public function updataInfo(param1:String, param2:Function = null, param3:Object = null) : void
      {
         if(!SceneHelper.checkScene(sceneName))
         {
            return;
         }
         this.type = param1;
         switch(param1)
         {
            case FbSuolideCommandConst.FB9_SUOLIDE_NPC136_BOSS_APPEAR:
               this.npc136_boss_appear();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_CAT_APPEAR:
               if(!TeamHelper.isCaptain())
               {
                  return;
               }
               this.notify(2,"#");
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_EXTI_APPEAR:
               if(!TeamHelper.isCaptain())
               {
                  return;
               }
               this.exti_appear();
         }
      }
      
      private function fightwith() : void
      {
         this.falao.addEventListener(MouseEvent.CLICK,this.fightWithFalao);
         this.fightWithFalao(null);
      }
      
      private function npc136_boss_appear() : void
      {
         DisplayUtil.stopAndRemove(this.coffin);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_appear") as Class;
         this.appearfalao = new _loc1_() as MovieClip;
         this.appearfalao.addFrameScript(this.appearfalao.totalFrames - 1,this.appearfalao_end);
         this.appearfalao.x = 483.5;
         this.appearfalao.y = 585.45;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.appearfalao);
         this.appearfalao.gotoAndPlay(1);
      }
      
      private function talkwithfalao(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.falao.removeEventListener(MouseEvent.CLICK,this.talkwithfalao);
         this.notify(-1,"fb9_suolide_npc136_boss_appear");
      }
      
      private function appearfalao_end() : void
      {
         this.appearfalao.stop();
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_falao") as Class;
         this.falao = new _loc1_() as MovieClip;
         this.falao.x = 458;
         this.falao.y = 339;
         this.falao.buttonMode = true;
         this.falao.addEventListener(MouseEvent.CLICK,this.talkwithfalao);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.falao);
      }
      
      private function fightWithFalao(param1:MouseEvent) : void
      {
         if(param1 != null)
         {
            param1.stopImmediatePropagation();
         }
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(this.petid);
      }
      
      private function onFightFail(param1:PetFightEvent) : void
      {
         this.isClicking = false;
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         if(!param1.isWin && !param1.isEscape)
         {
            FBCommonHelper.leavFBonLost();
         }
         else if(param1.isWin)
         {
            this.falao.removeEventListener(MouseEvent.CLICK,this.fightWithFalao);
            this.notify(-1,"fb9_suolide_fightwith");
         }
      }
      
      private function npc133_appear() : void
      {
         var _loc1_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         var _loc2_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_landing_appear") as Class;
         this.landing_appear = new _loc2_() as MovieClip;
         this.landing_appear.addFrameScript(this.landing_appear.totalFrames - 1,this.landing_appear_end);
         this.landing_appear.x = 270;
         this.landing_appear.y = 480;
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.landing_appear);
         this.landing_appear.gotoAndPlay(1);
      }
      
      private function landing_appear_end() : void
      {
         this.landing_appear.stop();
         this.notify(-1,"fb9_suolide_npc133_appear");
      }
      
      private function fight_win() : void
      {
         DisplayUtil.stopAndRemove(this.landing_appear);
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_landing_disappear") as Class;
         this.landing_disappear = new _loc1_() as MovieClip;
         this.landing_disappear.addFrameScript(this.landing_disappear.totalFrames - 1,this.landing_disappear_end);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.landing_disappear);
         this.landing_disappear.gotoAndPlay(1);
      }
      
      private function landing_disappear_end() : void
      {
         this.landing_disappear.stop();
         DisplayUtil.stopAndRemove(this.falao);
         DisplayUtil.stopAndRemove(this.landing_disappear);
         this.notify(-1,"fb9_suolide_fight_win");
      }
      
      private function cat_appear() : void
      {
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_cat_appear") as Class;
         this.cat_disappear = new _loc1_() as MovieClip;
         this.cat_disappear.x = 270;
         this.cat_disappear.y = 480;
         this.cat_disappear.addFrameScript(this.cat_disappear.totalFrames - 1,this.cat_disappear_end);
         SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(this.cat_disappear);
      }
      
      private function cat_disappear_end() : void
      {
         this.cat_disappear.stop();
         DisplayUtil.stopAndRemove(this.cat_disappear);
         this.notify(-1,"fb9_suolide_cat_appear");
      }
      
      private function present() : void
      {
         this.onfbaixiwin();
      }
      
      private function onHitExit(param1:ClickAndHitEvent) : void
      {
         this.fbservice.finishFB(null);
      }
      
      private function exti_appear() : void
      {
         this.currentMovieFinish(-1,"fb9_suolide_exti_appear");
      }
      
      private function onfbaixiwin() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("fbservice/fbaixiend",this.onLoadedRes);
      }
      
      private function onLoadedRes(param1:DisplayObject) : void
      {
         ProgressFullSprite.close();
         var _loc2_:IFBTeamService = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         var _loc3_:Class = ApplicationDomain.currentDomain.getDefinition("mmo.fbpanels.fbsuolide.FbSuolideWin") as Class;
         var _loc4_:Sprite = new _loc3_(_loc2_.currentFBInfo.fbLevel,this.callback) as Sprite;
         ModalDialogManager.getInstance().addModalDialog(_loc4_);
      }
      
      private function callback() : void
      {
         FBCommonHelper.leaveFB();
      }
      
      override public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         FBTeamSynchronizedEventDispatcher.instance.removeEventListener(FBTeamSynchronizedEvent.cmdNotify,this.onNotify);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         if(this.falao != null)
         {
            this.falao.removeEventListener(MouseEvent.CLICK,this.fightWithFalao);
            this.falao.removeEventListener(MouseEvent.CLICK,this.talkwithfalao);
         }
         if(this.exitsuolide9 != null)
         {
            this.exitsuolide9.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         }
      }
   }
}

