package mmo.fbservice.fbsuolide.fbsceneplayer.scene3
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.auto.ScenePlayerStepBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneManager;
   
   public class SuolidePlayer3_2MummyGame extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var type:String = null;
      
      private var fbservice:IFbService = null;
      
      private var disappear_landing:MovieClip = null;
      
      private var Gai3:Array = [];
      
      private var mark:Array = [];
      
      private var coffin:Array = [];
      
      private var kong:Array = [];
      
      private var fight_win:Boolean = true;
      
      private var num:int;
      
      private var petid:int = 1;
      
      public function SuolidePlayer3_2MummyGame()
      {
         super();
         this.gameInit();
      }
      
      public function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         this.type = param1;
         this.mummy_game();
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
         this.removeModalDialogMovieByName("appear_landing");
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Disappear_landing") as Class;
         this.disappear_landing = new _loc2_() as MovieClip;
         this.addModalDialogMovieToScene(this.disappear_landing,this.disappear_landing_end,204,391);
      }
      
      private function disappear_landing_end() : void
      {
         this.disappear_landing.stop();
         ModalDialogManager.getInstance().removeModalDialog(this.disappear_landing);
      }
      
      private function gameInit() : void
      {
         var _loc10_:MovieClip = null;
         this.removeSceneInfo();
         this.fbservice = ServiceContainer.getService(IFbService) as IFbService;
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Gai_suolide3") as Class;
         var _loc2_:int = int(Math.random() * 5);
         var _loc3_:int = this.onSetRandom(_loc2_);
         this.mark[_loc2_] = "exit";
         this.mark[_loc3_] = "present";
         var _loc4_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Monster_suolide3") as Class;
         var _loc5_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Exit_suolide3") as Class;
         var _loc6_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Present_suolide3") as Class;
         var _loc7_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Kong_suolide3") as Class;
         var _loc8_:int = 0;
         while(_loc8_ < 5)
         {
            if(_loc8_ == _loc2_)
            {
               this.coffin[_loc8_] = new _loc5_() as MovieClip;
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
         var _loc2_:ITaskService = null;
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
               _loc2_ = ServiceContainer.getService(ITaskService) as ITaskService;
               if(Boolean(_loc2_.isUserTaskDoing(567)) && Boolean(_loc2_.isUserTaskDoing(571)))
               {
                  TaskEventDispatcher.instance.dispatchEvent(new TaskEvent(TaskEvent.ON_CLIENT_STEP,{"taskId":571}));
               }
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
      
      private function exit_end() : void
      {
         this.isClicking = false;
         MovieClip(this.coffin[this.num]).stop();
         this.movieFinish(4,"exit_end");
      }
      
      private function present_end() : void
      {
         this.isClicking = false;
         MovieClip(this.coffin[this.num]).stop();
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.coffin[this.num]);
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.kong[this.num]);
         this.fbservice.addEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         this.fbservice.tryGetCaseAtCurrentScene(null);
         this.movieFinish(3,"present_end");
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
         var _loc3_:IMaterialGetPanel = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Array = null;
         var _loc7_:Object = null;
         (param1.target as EventDispatcher).removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         var _loc2_:Boolean = param1.param.succ as Boolean;
         if(_loc2_)
         {
            _loc3_ = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
            _loc4_ = 0;
            _loc5_ = 0;
            _loc6_ = param1.param.bonus as Array;
            for each(_loc7_ in _loc6_)
            {
               if(_loc7_.type == MaterialTypes.MONEY)
               {
                  _loc4_ = int(_loc7_.num);
               }
               else if(_loc7_.type == MaterialTypes.EXP)
               {
                  _loc5_ = int(_loc7_.num);
               }
               else
               {
                  _loc3_.showTips(_loc7_.type,_loc7_.id,_loc7_.num);
               }
            }
            if(_loc4_ > 0 || _loc5_ > 0)
            {
               _loc3_.showGetMoneyAndExpPanel(_loc4_,_loc5_);
            }
         }
         else
         {
            NewDialog.showFailMessage("很抱歉，这个宝箱是空的！");
         }
      }
      
      private function fightWithMummy(param1:MouseEvent) : void
      {
         var _loc2_:IPetFight = null;
         this.coffin[this.num].removeEventListener(MouseEvent.CLICK,this.fightWithMummy);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         _loc2_ = ServiceContainer.getService(IPetFight) as IPetFight;
         _loc2_.fightInCopy(this.petid);
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
         if(!(!param1.isWin && !param1.isEscape))
         {
            if(param1.isWin)
            {
               ++this.petid;
               this.fight_win = true;
               this.coffin[this.num].removeEventListener(MouseEvent.CLICK,this.fightWithMummy);
               SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.coffin[this.num]);
               SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.kong[this.num]);
            }
            else
            {
               this.coffin[this.num].addEventListener(MouseEvent.CLICK,this.fightWithMummy);
            }
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
         this.removeListen();
         this.isClicking = false;
         this.fbservice.removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
      }
   }
}

