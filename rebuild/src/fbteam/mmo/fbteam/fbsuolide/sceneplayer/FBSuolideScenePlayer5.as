package mmo.fbteam.fbsuolide.sceneplayer
{
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.fbteam.auto.*;
   import mmo.fbteam.common.SceneHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.fbsuolide.FbSuolideCommandConst;
   import mmo.fbteam.fbsuolide.sceneplayer.scene05.FBSuolide5_0StoneInfo;
   import mmo.fbteam.fbsuolide.sceneplayer.scene05.FBSuolide5_1Npc133Appear;
   import mmo.fbteam.fbsuolide.sceneplayer.scene05.FBSuolide5_2GoGo;
   import mmo.fbteam.fbsuolide.sceneplayer.scene05.FBSuolide5_3Balance;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.scene.SceneManager;
   
   public class FBSuolideScenePlayer5 extends FBScenePlayerBase
   {
      
      private static const sceneName:String = "fbsuolide5";
      
      private var mcBalance:MovieClip = null;
      
      private var mcGo:MovieClip = null;
      
      private var mcYardL:MovieClip = null;
      
      private var mcYardR:MovieClip = null;
      
      private var btnReset:SimpleButton = null;
      
      private var cat:ScenePlayer = null;
      
      public function FBSuolideScenePlayer5()
      {
         super();
      }
      
      override public function init() : void
      {
         super.init();
         this.resInit();
         this.updataInfo(FbSuolideCommandConst.FB5_SUOLIDE_FLAGSTONE_INFO);
      }
      
      private function resInit() : void
      {
         var _loc1_:DisplayObjectContainer = SceneManager.getInstance().loadedSceneInfo.scene.container;
         this.mcBalance = _loc1_.getChildByName("mc_balance") as MovieClip;
         this.mcYardL = _loc1_.getChildByName("mc_yardL") as MovieClip;
         this.mcYardL.gotoAndStop(1);
         this.mcYardR = _loc1_.getChildByName("mc_yardR") as MovieClip;
         this.mcYardR.gotoAndStop(1);
         this.mcGo = this.mcBalance.getChildByName("mc_go") as MovieClip;
         this.btnReset = this.mcGo.getChildByName("btn_reset") as SimpleButton;
         TipsManager.getInstance().addTips(this.btnReset,"天平重置");
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
            case FbSuolideCommandConst.FB5_SUOLIDE_FLAGSTONE_INFO:
               this.playerStep = new FBSuolide5_0StoneInfo();
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_NPC133_APPEAR:
               this.playerStep = new FBSuolide5_1Npc133Appear();
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_ARROWHEAD_CHANGE:
               this.playerStep = new FBSuolide5_2GoGo();
               break;
            case FbSuolideCommandConst.FB5_SUOLIDE_BALANCE:
               this.playerStep = new FBSuolide5_3Balance();
               this.showHelloTalk();
               break;
            default:
               this.playerStep = null;
         }
         if(null != this.playerStep)
         {
            this.playerStep.run(param1,param2,param3);
         }
      }
      
      private function showHelloTalk() : void
      {
         if(!TeamHelper.isCaptain())
         {
            return;
         }
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
         var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbsuolide.fbsuolide5.FlagStone") as Class;
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
         this.disposeStepPlayer();
      }
   }
}

