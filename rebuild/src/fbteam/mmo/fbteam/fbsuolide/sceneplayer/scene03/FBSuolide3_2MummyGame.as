package mmo.fbteam.fbsuolide.sceneplayer.scene03
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.common.FBCommonHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.sceneplayer.FBSuolideScenePlayerBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fbteam.IFBTeamService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolide3_2MummyGame extends FBSuolideScenePlayerBase implements IScenePlayerStep
   {
      
      private var sysData:Object = {"what":FBSuolide_Scene3TempTypes.FBSuolide3_2MummyGame};
      
      private var sysData2:Object = {"what":FBSuolide_Scene3TempTypes.FBSuolide3_2MummyGame_1};
      
      private var sysData3:Object = {"what":FBSuolide_Scene3TempTypes.FBSuolide3_2MummyGame_1 + "1"};
      
      private var sysData4:Object = {"what":FBSuolide_Scene3TempTypes.FBSuolide3_2MummyGame_1 + "2"};
      
      private var fbteam:IFBTeamService = null;
      
      private var disappear_landing:MovieClip = null;
      
      private var Gai3:Array = [];
      
      private var mark:Array = [];
      
      private var coffin:Array = [];
      
      private var kong:Array = [];
      
      private var fight_win:Boolean = true;
      
      private var num:int;
      
      private var petid:int = 1;
      
      public function FBSuolide3_2MummyGame()
      {
         super();
         this.gameInit();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.setSycFunWithKeyAndAction(this.mummy_game,this.sysData,"fb_suolide3_talk_1_end");
         this.setNotify(this.openEnd,this.sysData2);
         this.setNotify(this.getBonus,this.sysData3);
         this.setNotify(this.exitConfirm,this.sysData4);
      }
      
      private function mummy_game() : void
      {
         var _loc1_:* = 0;
         while(_loc1_ < 5)
         {
            this.Gai3[_loc1_].addEventListener(MouseEvent.CLICK,this.onClickCoffin);
            this.Gai3[_loc1_].buttonMode = true;
            _loc1_++;
         }
         this.removeChildByName("appear_landing");
         var _loc2_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Disappear_landing") as Class;
         this.disappear_landing = new _loc2_() as MovieClip;
         this.addMovieToScene(this.disappear_landing,this.disappear_landing_end,204,391);
      }
      
      private function disappear_landing_end() : void
      {
         this.disappear_landing.stop();
         DisplayUtil.stopAndRemove(this.disappear_landing);
      }
      
      private function gameInit() : void
      {
         var _loc10_:MovieClip = null;
         this.removeSceneInfo();
         this.fbteam = ServiceContainer.getService(IFBTeamService) as IFBTeamService;
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Gai_suolide3") as Class;
         var _loc2_:int = int(Math.random() * 5);
         var _loc3_:int = this.onSetRandom(_loc2_);
         this.mark[_loc2_] = "exit";
         this.mark[_loc3_] = "present";
         var _loc4_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Monster_suolide3") as Class;
         var _loc5_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Exit_suolide3") as Class;
         var _loc6_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Present_suolide3") as Class;
         var _loc7_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.Kong_suolide3") as Class;
         var _loc8_:int = 0;
         while(_loc8_ < 5)
         {
            if(_loc8_ == _loc2_)
            {
               this.coffin[_loc8_] = new _loc5_() as MovieClip;
               this.coffin[_loc8_].name = "fbsuolide_3_3_exit";
            }
            else if(_loc8_ == _loc3_)
            {
               this.coffin[_loc8_] = new _loc6_() as MovieClip;
            }
            else
            {
               this.coffin[_loc8_] = new _loc4_() as MovieClip;
            }
            this.coffin[_loc8_].x = 180.45 + 135 * _loc8_;
            this.coffin[_loc8_].y = 230.25;
            MovieClip(this.coffin[_loc8_]).buttonMode = true;
            _loc8_++;
         }
         var _loc9_:int = 0;
         while(_loc9_ < 5)
         {
            _loc10_ = new _loc1_() as MovieClip;
            _loc10_.mouseChildren = false;
            _loc10_.x = 180.45 + 135 * _loc9_;
            _loc10_.y = 230.25;
            _loc10_.name = "coffin" + _loc9_;
            SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(_loc10_);
            _loc10_.stop();
            this.Gai3[_loc9_] = _loc10_;
            _loc9_++;
         }
         _loc9_ = 0;
         while(_loc9_ < 5)
         {
            this.kong[_loc9_] = new _loc7_() as MovieClip;
            this.kong[_loc9_].x = 180.45 + 135 * _loc9_;
            this.kong[_loc9_].y = 230.25;
            _loc9_++;
         }
      }
      
      private function removeSceneInfo() : void
      {
         var _loc2_:DisplayObject = null;
         var _loc1_:int = 0;
         while(_loc1_ < 5)
         {
            _loc2_ = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("coffin" + _loc1_) as DisplayObject;
            DisplayUtil.stopAndRemove(_loc2_);
            _loc1_++;
         }
      }
      
      private function onClickCoffin(param1:MouseEvent) : void
      {
         if(!this.fight_win)
         {
            NewDialog.showFailMessage("要先打败木乃伊，才能打开其他的木乃伊之棺哦。");
            return;
         }
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.num = int((param1.target as DisplayObject).name.substr(6));
         this.Gai3[this.num].removeEventListener(MouseEvent.CLICK,this.onClickCoffin);
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.Gai3[this.num]);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.coffin[this.num]);
         MovieClip(this.coffin[this.num]).stop();
         switch(this.mark[this.num])
         {
            case "exit":
               MovieClip(this.coffin[this.num]).addFrameScript(this.coffin[this.num].totalFrames - 1,this.exit_end);
               MovieClip(this.coffin[this.num]).gotoAndPlay(1);
               break;
            case "present":
               MovieClip(this.coffin[this.num]).addFrameScript(this.coffin[this.num].totalFrames - 1,this.present_end);
               MovieClip(this.coffin[this.num]).gotoAndPlay(1);
               break;
            default:
               this.fight_win = false;
               MovieClip(this.coffin[this.num]).addFrameScript(this.coffin[this.num].totalFrames - 1,this.fight_end);
               MovieClip(this.coffin[this.num]).gotoAndPlay(1);
         }
      }
      
      private function onSetRandom(param1:int) : int
      {
         var _loc2_:int = int(Math.random() * 5);
         if(_loc2_ == param1)
         {
            return this.onSetRandom(param1);
         }
         return _loc2_;
      }
      
      private function getBonus(param1:Object) : void
      {
         var _loc2_:ITaskNpcService = null;
         if(TeamHelper.isCaptain())
         {
            this.isClicking = false;
            _loc2_ = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
            _loc2_.showNpcPanelFreely("fbsuolide3_rewardWay",16);
         }
         this.openEnd(param1);
      }
      
      private function exit_end() : void
      {
         this.isClicking = false;
         MovieClip(this.coffin[this.num]).stop();
         this.notify(this.sysData4);
      }
      
      private function exitConfirm() : void
      {
         this.finishStep();
      }
      
      private function present_end() : void
      {
         MovieClip(this.coffin[this.num]).stop();
         this.fbteam.addEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         this.fbteam.tryGetCurrentCase({});
      }
      
      private function openEnd(param1:Object) : void
      {
         var _loc2_:int = int(param1.n);
         DisplayUtil.stopAndRemove(this.coffin[_loc2_]);
         DisplayUtil.stopAndRemove(this.Gai3[_loc2_]);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.kong[_loc2_]);
      }
      
      private function fight_end() : void
      {
         this.isClicking = false;
         MovieClip(this.coffin[this.num]).stop();
         this.coffin[this.num].addEventListener(MouseEvent.CLICK,this.fightWithMummy);
         this.fightWithMummy(null);
      }
      
      private function onGetCase(param1:FbEvent) : void
      {
         (param1.target as EventDispatcher).removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         var _loc2_:Boolean = param1.param.succ as Boolean;
         if(_loc2_)
         {
            this.addNotifyParams(this.sysData3,{"n":this.num});
            this.notify(this.sysData3);
         }
      }
      
      private function fightWithMummy(param1:MouseEvent) : void
      {
         var _loc2_:IPetFight = null;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         _loc2_ = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(this.petid);
      }
      
      private function sysData2Fun() : void
      {
         this.addNotifyParams(this.sysData2,{"n":this.num});
         this.notify(this.sysData2);
      }
      
      private function onFightFail(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         this.coffin[this.num].addEventListener(MouseEvent.CLICK,this.fightWithMummy);
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(param1.id != this.petid)
         {
            return;
         }
         if(!param1.isWin && !param1.isEscape)
         {
            FBCommonHelper.leavFBonLost();
         }
         else if(param1.isWin)
         {
            ++this.petid;
            this.fight_win = true;
            this.coffin[this.num].removeEventListener(MouseEvent.CLICK,this.fightWithMummy);
            this.sysData2Fun();
         }
         else
         {
            this.coffin[this.num].addEventListener(MouseEvent.CLICK,this.fightWithMummy);
         }
      }
      
      private function removeListen() : void
      {
         var _loc1_:* = 0;
         while(_loc1_ < 5)
         {
            this.coffin[_loc1_].removeEventListener(MouseEvent.CLICK,this.onClickCoffin);
            this.Gai3[_loc1_].removeEventListener(MouseEvent.CLICK,this.onClickCoffin);
            _loc1_++;
         }
      }
      
      public function dispose() : void
      {
         super.disposeEvt();
      }
   }
}

