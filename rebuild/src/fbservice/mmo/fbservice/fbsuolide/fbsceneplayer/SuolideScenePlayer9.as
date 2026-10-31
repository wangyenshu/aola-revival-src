package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.system.ApplicationDomain;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.ShootServiceEvent;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class SuolideScenePlayer9 extends FBScenePlayerBase
   {
      
      private var appearfalao:MovieClip;
      
      private var coffin_open:MovieClip;
      
      private var falao:MovieClip;
      
      private var landing_appear:MovieClip;
      
      private var landing_disappear:MovieClip;
      
      private var coffin:MovieClip;
      
      private var petid:int = 1;
      
      private var fbservice:IFbService = ServiceContainer.getService(IFbService) as IFbService;
      
      private var stoneMC:MovieClip;
      
      private var coffin_open_state:MovieClip;
      
      private var ss:IShootService;
      
      private var exitsuolide9:MovieClip;
      
      private var cat_disappear:MovieClip;
      
      private var cat:DisplayObject;
      
      private var taskService:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
      
      private var fire:MovieClip;
      
      public function SuolideScenePlayer9()
      {
         super();
      }
      
      override public function init() : void
      {
         this.gameInit();
      }
      
      private function gameInit() : void
      {
         this.cat = this.fbservice.addFollower(29999);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_coffin") as Class;
         this.coffin = new _loc1_() as MovieClip;
         this.coffin.x = 462.6;
         this.coffin.y = 339;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.coffin);
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         switch(param1)
         {
            case FbSuolideCommandConst.FB9_SUOLIDE_NPC136_BOSS_APPEAR:
               this.npc136_boss_appear();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_FIGHTWITH:
               this.fightwith();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_NPC133_APPEAR:
               this.npc133_appear();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_FIGHT_WIN:
               this.fight_win();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_CAT_APPEAR:
               this.cat_appear();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_PRESENT:
               this.present();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_STELAE_DISTROY:
               this.stelae_distroy();
               break;
            case FbSuolideCommandConst.FB9_SUOLIDE_EXTI_APPEAR:
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
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_appear") as Class;
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
         this.movieFinish(-1,"fb9_suolide_npc136_boss_appear");
      }
      
      private function appearfalao_end() : void
      {
         this.appearfalao.stop();
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_falao") as Class;
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
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         var _loc2_:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(this.petid);
      }
      
      private function onFightFail(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         this.isClicking = false;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(param1.id != this.petid)
         {
            return;
         }
         if(!param1.isWin && !param1.isEscape)
         {
            this.fbservice.leaveFb({"force":true});
            NewDialog.showFailMessage("战斗失败，你已被踢出副本");
         }
         else if(param1.isWin)
         {
            this.falao.removeEventListener(MouseEvent.CLICK,this.fightWithFalao);
            this.movieFinish(-1,"fb9_suolide_fightwith");
         }
      }
      
      private function npc133_appear() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_landing_appear") as Class;
         this.landing_appear = new _loc1_() as MovieClip;
         this.landing_appear.addFrameScript(this.landing_appear.totalFrames - 1,this.landing_appear_end);
         ModalDialogManager.getInstance().addModalDialog(this.landing_appear,AlignType.NONE,PanelEffect.NONE,true,270,480);
         this.landing_appear.gotoAndPlay(1);
      }
      
      private function landing_appear_end() : void
      {
         this.landing_appear.stop();
         this.movieFinish(-1,"fb9_suolide_npc133_appear");
      }
      
      private function fight_win() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this.landing_appear);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_landing_disappear") as Class;
         this.landing_disappear = new _loc1_() as MovieClip;
         this.landing_disappear.addFrameScript(this.landing_disappear.totalFrames - 1,this.landing_disappear_end);
         ModalDialogManager.getInstance().addModalDialog(this.landing_disappear,AlignType.NONE,PanelEffect.NONE,true,0,0);
         this.landing_disappear.gotoAndPlay(1);
      }
      
      private function landing_disappear_end() : void
      {
         this.landing_disappear.stop();
         DisplayUtil.stopAndRemove(this.falao);
         ModalDialogManager.getInstance().removeModalDialog(this.landing_disappear);
         this.movieFinish(-1,"fb9_suolide_fight_win");
      }
      
      private function cat_appear() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_cat_appear") as Class;
         this.cat_disappear = new _loc1_() as MovieClip;
         this.cat_disappear.addFrameScript(this.cat_disappear.totalFrames - 1,this.cat_disappear_end);
         var _loc2_:Point = this.cat.localToGlobal(new Point(0,0));
         ModalDialogManager.getInstance().addModalDialog(this.cat_disappear,AlignType.NONE,PanelEffect.NONE,true,_loc2_.x,_loc2_.y);
         this.cat.visible = false;
      }
      
      private function cat_disappear_end() : void
      {
         this.cat_disappear.stop();
         ModalDialogManager.getInstance().removeModalDialog(this.cat_disappear);
         this.cat.visible = true;
         this.movieFinish(-1,"fb9_suolide_cat_appear");
      }
      
      private function present() : void
      {
         this.onfbaixiwin();
      }
      
      private function stelae_distroy() : void
      {
         var mc2:MovieClip = null;
         var cls:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Background2") as Class;
         mc2 = new cls() as MovieClip;
         mc2.addFrameScript(mc2.totalFrames - 1,function():void
         {
            var pt:Point;
            var targetInfo:TargetInfo;
            var cls2:Class;
            var cls3:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Background3") as Class;
            var mc3:MovieClip = new cls3() as MovieClip;
            SceneManager.getInstance().loadedSceneInfo.scene.switchBackground(mc3);
            SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(coffin_open_state);
            stoneMC = mc3.getChildByName("stone") as MovieClip;
            ss = ServiceContainer.getService(IShootService) as IShootService;
            pt = new Point(stoneMC.x,stoneMC.y);
            targetInfo = new TargetInfo(stoneMC,"stone",ShootTargetTypes.Others,pt);
            ss.registerDefaultTarget(targetInfo);
            ss.addEventListener(ShootServiceEvent.onBump,onStoneShooted);
            DisplayUtil.stopAndRemove(mc2);
            movieFinish(-1,"fb9_suolide_stelae_distroy");
            cls2 = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_fire") as Class;
            fire = new cls2() as MovieClip;
            fire.addFrameScript(fire.totalFrames - 1,function():*
            {
               fire.stop();
            });
            SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(fire);
            fire.gotoAndPlay(1);
         });
         mc2.gotoAndStop(1);
         SceneManager.getInstance().loadedSceneInfo.scene.switchBackground(mc2);
         cls = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_coffin_open") as Class;
         this.coffin_open_state = new cls() as MovieClip;
         this.coffin_open_state.x = 462.6;
         this.coffin_open_state.y = 339;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.coffin_open_state);
         mc2.play();
      }
      
      private function onStoneShooted(param1:ShootServiceEvent) : void
      {
         var _loc2_:int = 0;
         var _loc5_:Class = null;
         var _loc3_:TargetInfo = param1.params.targetInfo as TargetInfo;
         var _loc4_:ShootInfo = param1.params.shootInfo as ShootInfo;
         if(_loc4_.from != SocketClient.instance.myUserName || _loc4_.cardId != 1)
         {
            return;
         }
         if(_loc3_.target == this.stoneMC)
         {
            if(this.stoneMC.currentFrame != 5)
            {
               this.stoneMC.gotoAndStop(this.stoneMC.currentFrame + 1);
            }
            else
            {
               DisplayUtil.stopAndRemove(this.fire);
               this.ss.removeEventListener(ShootServiceEvent.onBump,this.onStoneShooted);
               _loc5_ = Tool.instence.getClass("mmo.scene.fbsuolide.Fbsuolide9_exitsuolide9") as Class;
               this.exitsuolide9 = new _loc5_() as MovieClip;
               this.exitsuolide9.alpha = 0;
               this.exitsuolide9.x = 867;
               this.exitsuolide9.y = 161;
               this.exitsuolide9.buttonMode = true;
               SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.exitsuolide9);
               ClickAndHitHelper.instance.registerTarget(this.exitsuolide9);
               this.exitsuolide9.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
               TipsManager.getInstance().addTips(this.exitsuolide9,"通往下一场景");
            }
         }
      }
      
      private function onHitExit(param1:ClickAndHitEvent) : void
      {
         if(Boolean(this.taskService.isUserTaskDoing(567)) && !this.taskService.isUserTaskFinish(577))
         {
            SceneManager.getInstance().loadFB("fbsuolide10","fbsuolide");
         }
         else
         {
            this.fbservice.leaveFb({"force":true});
         }
      }
      
      private function exti_appear() : void
      {
         if(Boolean(this.taskService.isUserTaskDoing(567)) && Boolean(this.taskService.isUserTaskDoing(576)))
         {
            TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":576}));
         }
         this.movieFinish(-1,"fb9_suolide_exti_appear");
      }
      
      private function onfbaixiwin() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("fbservice/fbaixiend",this.onLoadedRes);
      }
      
      private function onLoadedRes(param1:DisplayObject) : void
      {
         ProgressFullSprite.close();
         var _loc2_:IFbService = ServiceContainer.getService(IFbService) as IFbService;
         var _loc3_:Class = ApplicationDomain.currentDomain.getDefinition("mmo.fbpanels.fbsuolide.FbSuolideWin") as Class;
         var _loc4_:Sprite = new _loc3_(_loc2_.currentFbLevel,this.callback) as Sprite;
         ModalDialogManager.getInstance().addModalDialog(_loc4_);
      }
      
      private function callback() : void
      {
         if(this.taskService.isUserTaskDoing(567))
         {
            this.movieFinish(-1,"fb9_suolide_present");
         }
         else
         {
            SceneManager.getInstance().loadedSceneInfo.scene.needValidateLeave = false;
            SceneManager.getInstance().loadScene("suolide2");
         }
      }
      
      override public function dispose() : void
      {
         this.isClicking = false;
         if(this.falao != null)
         {
            this.falao.removeEventListener(MouseEvent.CLICK,this.fightWithFalao);
            this.falao.removeEventListener(MouseEvent.CLICK,this.talkwithfalao);
         }
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(this.ss != null)
         {
            this.ss.removeEventListener(ShootServiceEvent.onBump,this.onStoneShooted);
         }
         if(this.exitsuolide9 != null)
         {
            this.exitsuolide9.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onHitExit);
         }
      }
   }
}

