package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.FbEvent;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.ITaskService;
   import mmo.play.scene.SceneManager;
   
   public class SuolideScenePlayer7 extends FBScenePlayerBase
   {
      
      private var fbservice:IFbService = ServiceContainer.getService(IFbService) as IFbService;
      
      private var tasknpcservice:ITaskNpcService = ServiceContainer.instance.getService(ITaskNpcService) as ITaskNpcService;
      
      private var flower_suolide:MovieClip;
      
      private var appear_mzsh:MovieClip;
      
      private var mzsh_fight:DisplayObject;
      
      private var cast_coin:MovieClip;
      
      private var stair:MovieClip;
      
      private var appear_stair:MovieClip;
      
      private var Monster1:MovieClip;
      
      private var Monster2:MovieClip;
      
      private var present:MovieClip;
      
      private var mark:String;
      
      private var taskService:ITaskService;
      
      private var cat:DisplayObject;
      
      private var isLateralMode:Boolean = false;
      
      public function SuolideScenePlayer7()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.taskService = ServiceContainer.instance.getService(ITaskService) as ITaskService;
         this.cat = this.fbservice.addFollower(29999);
      }
      
      override public function updataInfo(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void
      {
         switch(param1)
         {
            case FbSuolideCommandConst.FB7_SUOLIDE_FLOWEROFSUOLIDE:
               this.fb7_suolide_flowerOfSuolide();
               break;
            case FbSuolideCommandConst.FB7_SUOLIDE_ADDSUOLIDE_FLOWER:
               SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.mzsh_fight);
               this.fb7_suolide_fightWithMzsh();
               break;
            case FbSuolideCommandConst.FB7_SUOLIDE_FIGHTWITHMZSH:
               this.fb7_suolide_fightWithMzsh();
               break;
            case FbSuolideCommandConst.FB7_SUOLIDE_LEAVE:
               this.fb7_suolide_leave();
               break;
            case FbSuolideCommandConst.FB7_SUOLIDE_REMOVEMANZHUSHAHUA:
               this.cat.visible = false;
               SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.mzsh_fight);
               break;
            case FbSuolideCommandConst.FB7_SUOLIDE_ENABLECAT:
               this.cat.visible = true;
         }
      }
      
      private function fb7_suolide_flowerOfSuolide() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Flower") as Class;
         this.flower_suolide = new _loc1_() as MovieClip;
         this.flower_suolide.x = 269;
         this.flower_suolide.y = 313;
         this.flower_suolide.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.flower_suolide);
         this.flower_suolide.addEventListener(MouseEvent.CLICK,this.appear_Mzsh);
      }
      
      private function appear_Mzsh(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.flower_suolide.removeEventListener(MouseEvent.CLICK,this.appear_Mzsh);
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.flower_suolide);
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Appear_mzsh") as Class;
         this.appear_mzsh = new _loc2_() as MovieClip;
         this.appear_mzsh.addFrameScript(this.appear_mzsh.totalFrames - 1,this.speak);
         ModalDialogManager.getInstance().addModalDialog(this.appear_mzsh,AlignType.NONE,PanelEffect.NONE,true,0,0);
         this.appear_mzsh.gotoAndPlay(1);
      }
      
      private function speak() : void
      {
         this.appear_mzsh.stop();
         ModalDialogManager.getInstance().removeModalDialog(this.appear_mzsh);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Mzsh") as Class;
         this.mzsh_fight = new _loc1_() as DisplayObject;
         this.mzsh_fight.x = 268.7;
         this.mzsh_fight.y = 332.6;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.mzsh_fight);
         this.mark = "mzsh";
         this.mzsh_fight.addEventListener(MouseEvent.CLICK,this.fightWith);
         if(Boolean(this.taskService.isUserTaskFinish(567)) && Boolean(this.taskService.isTaskCanStart(579)))
         {
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.mzsh_fight);
            CommonEventDispatcher.instance.dispatchEvent(new Event("StartTask579"));
            return;
         }
         if(Boolean(this.taskService.isUserTaskDoing(579)) && Boolean(this.taskService.isUserTaskDoing(580)))
         {
            return;
         }
         this.movieFinish(-1,"fb7_suolide_flowerOfSuolide");
      }
      
      private function fb7_suolide_fightWithMzsh() : void
      {
         this.fightWith(null);
      }
      
      private function fightWith(param1:MouseEvent) : void
      {
         var _loc2_:IPetFight = null;
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
         _loc2_ = ServiceContainer.getService(IPetFight) as IPetFight;
         switch(this.mark)
         {
            case "mzsh":
               _loc2_.fightInCopy(3);
               break;
            case "Click1":
               _loc2_.fightInCopy(1);
               break;
            case "Click2":
               _loc2_.fightInCopy(2);
               break;
            case "Click3":
         }
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
         if(!param1.isWin && !param1.isEscape)
         {
            this.fbservice.leaveFb({"force":true});
            NewDialog.showFailMessage("战斗失败，你已被踢出副本");
         }
         else if(param1.isWin)
         {
            switch(this.mark)
            {
               case "mzsh":
                  this.mzsh_fight.removeEventListener(MouseEvent.CLICK,this.fightWith);
                  if(Boolean(this.taskService.isUserTaskDoing(579)) && Boolean(this.taskService.isUserTaskDoing(580)))
                  {
                     CommonEventDispatcher.instance.dispatchEvent(new Event("fb7fightWithMzsh"));
                     return;
                  }
                  this.movieFinish(-1,"fb7_suolide_fightWithMzsh");
                  break;
               case "Click1":
                  this.Monster1.removeEventListener(MouseEvent.CLICK,this.fightWith);
                  SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.Monster1);
                  this.mark = "Click2";
                  this.cast_coin.addEventListener(MouseEvent.CLICK,this.onClickCoin);
                  break;
               case "Click2":
                  this.Monster2.removeEventListener(MouseEvent.CLICK,this.fightWith);
                  SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.Monster2);
                  this.mark = "Click3";
                  this.cast_coin.addEventListener(MouseEvent.CLICK,this.onClickCoin);
            }
         }
      }
      
      private function fb7_suolide_leave() : void
      {
         if(this.mzsh_fight.parent == SceneManager.getInstance().loadedSceneInfo.scene.container)
         {
            SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.mzsh_fight);
         }
         this.fight137_end();
      }
      
      private function fight137_end() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Cast_coin") as Class;
         this.cast_coin = new _loc1_() as MovieClip;
         this.cast_coin.x = 121.6;
         this.cast_coin.y = 360.4;
         this.cast_coin.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.cast_coin);
         this.mark = "Click1";
         this.cast_coin.addEventListener(MouseEvent.CLICK,this.onClickCoin);
         var _loc2_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Stair7") as Class;
         this.stair = new _loc2_() as MovieClip;
         this.stair.x = 284.9;
         this.stair.y = 308.9;
         this.stair.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.backGround.addChild(this.stair);
         this.stair.addEventListener(MouseEvent.CLICK,this.onClickStair);
      }
      
      private function onClickCoin(param1:MouseEvent) : void
      {
         var str:String = null;
         var evt:MouseEvent = param1;
         switch(this.mark)
         {
            case "Click1":
               str = "这里有个投币口，是否投10晶币进去看看？";
               break;
            case "Click2":
               str = "这里有个投币口，是否投100晶币进去看看？";
               break;
            case "Click3":
               str = "这里有个投币口，是否投1000晶币进去看看？";
         }
         NewDialog.getCofirmDialog(str,function(param1:ModalDialog):void
         {
            param1.addEventListener(ModalDialogEvent.OK,this.confirmCoinOk);
            param1.addEventListener(ModalDialogEvent.CANCEL,this.confirmCoinCancel);
            param1.show();
         },this);
      }
      
      private function confirmCoinOk(param1:ModalDialogEvent) : void
      {
         var _loc2_:ModalDialog = param1.target as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.confirmCoinOk);
         _loc2_.removeEventListener(ModalDialogEvent.CANCEL,this.confirmCoinCancel);
         this.cast_coin.removeEventListener(MouseEvent.CLICK,this.onClickCoin);
         switch(this.mark)
         {
            case "Click1":
               this.ClickOK(10);
               break;
            case "Click2":
               this.ClickOK(100);
               break;
            case "Click3":
               this.ClickOK(1000);
         }
      }
      
      private function ClickOK(param1:int) : void
      {
         if(UserInfo.score < param1)
         {
            NewDialog.showFailMessage("真可怜，你实在是太穷了，连" + param1.toString() + "晶币都没有。");
         }
         else
         {
            SocketClient.instance.decreaseScore(param1);
            switch(param1)
            {
               case 10:
                  this.onClick1();
                  break;
               case 100:
                  this.onClick2();
                  break;
               case 1000:
                  this.onClick3();
            }
         }
      }
      
      private function onClick1() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fb7_monster1") as Class;
         this.Monster1 = new _loc1_() as MovieClip;
         this.Monster1.x = 285;
         this.Monster1.y = 414;
         this.Monster1.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.Monster1);
         this.Monster1.addEventListener(MouseEvent.CLICK,this.fightWith);
         this.fightWith(null);
      }
      
      private function onClick2() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fb7_monster2") as Class;
         this.Monster2 = new _loc1_() as MovieClip;
         this.Monster2.x = 285;
         this.Monster2.y = 414;
         this.Monster2.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.Monster2);
         this.Monster2.addEventListener(MouseEvent.CLICK,this.fightWith);
         this.fightWith(null);
      }
      
      private function onClick3() : void
      {
         this.cast_coin.removeEventListener(MouseEvent.CLICK,this.onClickCoin);
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.Fb7_present") as Class;
         this.present = new _loc1_() as MovieClip;
         this.present.x = 285;
         this.present.y = 414;
         this.present.buttonMode = true;
         SceneManager.getInstance().loadedSceneInfo.scene.container.addChild(this.present);
         this.present.addEventListener(MouseEvent.CLICK,this.onClickPresent);
      }
      
      private function onClickPresent(param1:MouseEvent) : void
      {
         SceneManager.getInstance().loadedSceneInfo.scene.container.removeChild(this.present);
         this.present.removeEventListener(MouseEvent.CLICK,this.onClickPresent);
         this.fbservice.addEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         this.fbservice.tryGetCaseAtCurrentScene(null);
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
      
      private function confirmCoinCancel(param1:ModalDialogEvent) : void
      {
         var _loc2_:ModalDialog = param1.target as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.confirmCoinOk);
         _loc2_.removeEventListener(ModalDialogEvent.CANCEL,this.confirmCoinCancel);
      }
      
      private function onClickStair(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         NewDialog.getCofirmDialog("是否使用传送梯？",function(param1:ModalDialog):void
         {
            param1.addEventListener(ModalDialogEvent.OK,this.confirmStairOk);
            param1.addEventListener(ModalDialogEvent.CANCEL,this.confirmStairCancel);
            param1.show();
         },this);
      }
      
      private function confirmStairOk(param1:ModalDialogEvent) : void
      {
         this.stair.removeEventListener(MouseEvent.CLICK,this.onClickStair);
         var _loc2_:ModalDialog = param1.target as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.confirmStairOk);
         _loc2_.removeEventListener(ModalDialogEvent.CANCEL,this.confirmStairCancel);
         this.movieFinish(-1,"fb7_suolide_leave");
         SceneManager.getInstance().loadFB("fbsuolide8","fbsuolide");
      }
      
      private function confirmStairCancel(param1:ModalDialogEvent) : void
      {
         var _loc2_:ModalDialog = param1.target as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.confirmStairOk);
         _loc2_.removeEventListener(ModalDialogEvent.CANCEL,this.confirmStairCancel);
      }
      
      override public function dispose() : void
      {
         if(this.flower_suolide != null)
         {
            this.flower_suolide.removeEventListener(MouseEvent.CLICK,this.appear_Mzsh);
         }
         if(this.mzsh_fight != null)
         {
            this.mzsh_fight.removeEventListener(MouseEvent.CLICK,this.fightWith);
         }
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(this.cast_coin != null)
         {
            this.cast_coin.removeEventListener(MouseEvent.CLICK,this.onClickCoin);
         }
         if(this.stair != null)
         {
            this.stair.removeEventListener(MouseEvent.CLICK,this.onClickStair);
         }
         if(this.Monster1 != null)
         {
            this.Monster1.removeEventListener(MouseEvent.CLICK,this.fightWith);
         }
         if(this.Monster2 != null)
         {
            this.Monster2.removeEventListener(MouseEvent.CLICK,this.fightWith);
         }
         if(this.present != null)
         {
            this.present.removeEventListener(MouseEvent.CLICK,this.fightWith);
         }
         if(this.fbservice != null)
         {
            this.fbservice.removeEventListener(FbEvent.ON_TRYGET_CASE,this.onGetCase);
         }
      }
   }
}

