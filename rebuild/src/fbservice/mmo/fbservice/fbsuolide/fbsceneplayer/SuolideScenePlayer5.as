package mmo.fbservice.fbsuolide.fbsceneplayer
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbservice.auto.FBScenePlayerBase;
   import mmo.fbservice.auto.IScenePlayerStep;
   import mmo.fbservice.common.tools.Tool;
   import mmo.fbservice.fbsuolide.FbSuolideCommandConst;
   import mmo.fbservice.fbsuolide.fbsceneplayer.scene5.*;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.fb.IFbService;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.sceneplayer.ScenePlayer;
   
   public class SuolideScenePlayer5 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide5";
      
      private var mcBalance:MovieClip = null;
      
      private var mcGo:MovieClip = null;
      
      private var mcYardL:MovieClip = null;
      
      private var mcYardR:MovieClip = null;
      
      private var btnReset:SimpleButton = null;
      
      private var cat:ScenePlayer = null;
      
      public function SuolideScenePlayer5()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.resInit();
         this.updataInfo(FbSuolideCommandConst.FB5_SUOLIDE_FLAGSTONE_INFO,true);
         var _loc1_:IFbService = ServiceContainer.instance.getService(IFbService) as IFbService;
         this.cat = _loc1_.addFollower(29999) as ScenePlayer;
         this.cat.name = "cat_Follower";
      }
      
      private function resInit() : void
      {
         this.mcBalance = this.sceneInfo.scene.container.getChildByName("mc_balance") as MovieClip;
         this.mcYardL = this.sceneInfo.scene.container.getChildByName("mc_yardL") as MovieClip;
         this.mcYardL.gotoAndStop(1);
         this.mcYardR = this.sceneInfo.scene.container.getChildByName("mc_yardR") as MovieClip;
         this.mcYardR.gotoAndStop(1);
         this.mcGo = this.mcBalance.getChildByName("mc_go") as MovieClip;
         this.btnReset = this.mcGo.getChildByName("btn_reset") as SimpleButton;
         TipsManager.getInstance().addTips(this.btnReset,"天平重置");
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
            case FbSuolideCommandConst.FB5_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new SuolidePlayer5_2GoGo() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_FLAGSTONE_INFO:
               this.playerStep = new SuolidePlayer5_00StoneInfo() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new SuolidePlayer5_1Npc133Appear() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_BALANCE:
               this.playerStep = new SuolidePlayer5_3Balance() as IScenePlayerStep;
               this.playerStep.init(param1,param2,param3,param4);
               this.showHelloTalk();
         }
      }
      
      private function showHelloTalk() : void
      {
         var _loc1_:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onHelloTalkFinish);
         _loc1_.showNpcPanelFreely("fbsuolide5_hellotalk",1);
      }
      
      private function onHelloTalkFinish(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action;
         if("fbsuolide5_hellotalk_finish" == _loc2_)
         {
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onHelloTalkFinish);
            this.showStoneInfo();
         }
         else if("fbsuolide5_hellotalk_finish_notsee" == _loc2_)
         {
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onHelloTalkFinish);
         }
      }
      
      private function showStoneInfo() : void
      {
         var _loc1_:Class = Tool.instence.getClass("mmo.scene.fbsuolide.fbsuolide5.FlagStone") as Class;
         var _loc2_:Sprite = new _loc1_() as Sprite;
         var _loc3_:SimpleButton = _loc2_.getChildByName("btnclose") as SimpleButton;
         _loc3_.addEventListener(MouseEvent.CLICK,this.onClose);
         ModalDialogManager.getInstance().addModalDialog(_loc2_,AlignType.MIDDLE_CENTER);
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.currentTarget as SimpleButton;
         _loc2_.removeEventListener(MouseEvent.CLICK,this.onClose);
         ModalDialogManager.getInstance().removeModalDialog(_loc2_.parent);
      }
      
      override public function dispose() : void
      {
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onHelloTalkFinish);
         this.disposeStepPlayer();
      }
   }
}

