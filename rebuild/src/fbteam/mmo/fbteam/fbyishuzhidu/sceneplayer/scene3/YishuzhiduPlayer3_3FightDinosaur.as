package mmo.fbteam.fbyishuzhidu.sceneplayer.scene3
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.configure.FBConfig;
   import mmo.fbteam.constant.FBTeamCommonTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.team.TeamSynchronizedClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   
   public class YishuzhiduPlayer3_3FightDinosaur extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var dinosaurAppearMovie:MovieClip;
      
      private var dinosaurFoot:MovieClip;
      
      private var isClick:Boolean = false;
      
      private var taskNpcService:ITaskNpcService;
      
      private const showDinosaurAction:int = 1;
      
      private const showDinosaurBegin:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":this.showDinosaurAction
      };
      
      private const showDinosaurEnd:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":this.showDinosaurAction
      };
      
      private const showPassCardAction:int = 2;
      
      private const showPassCardBegin:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_START,
         "what":this.showPassCardAction
      };
      
      private const showPassCardEnd:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":this.showPassCardAction
      };
      
      private const fightAction:int = 3;
      
      private const fightEndObject:Object = {
         "teamkey":TeamHelper.getTeamKey(),
         "type":FBTeamCommonTypes.TYPE_END,
         "what":this.fightAction
      };
      
      private var count1:int = 0;
      
      private var count2:int = 0;
      
      private var count3:int = 0;
      
      private var isPlayingDinosaurMovie:Boolean = true;
      
      private var isPlayingDisappearMovie:Boolean = true;
      
      private var passCard:MovieClip;
      
      public function YishuzhiduPlayer3_3FightDinosaur()
      {
         super();
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.dinosaurAppearMovie = this.sceneInfo.scene.backGround.getChildByName("dinosaurAppearMovie") as MovieClip;
         this.dinosaurAppearMovie.visible = false;
         this.dinosaurFoot = this.sceneInfo.scene.backGround.getChildByName("dinosaurFoot") as MovieClip;
         this.dinosaurFoot.buttonMode = true;
         this.dinosaurFoot.addEventListener(MouseEvent.CLICK,this.clickDinosaurFoot);
         SocketClient.instance.addEventListener(SocketClientEvent.onCustomCommand,this.actionShow);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
      }
      
      private function clickDinosaurFoot(param1:MouseEvent) : void
      {
         if(this.isClick)
         {
            return;
         }
         this.isClick = true;
         TeamSynchronizedClient.notify(this.showDinosaurBegin);
         this.showDinosaurMovie();
      }
      
      private function showDinosaurMovie() : void
      {
         this.dinosaurAppearMovie.visible = true;
         this.dinosaurAppearMovie.addFrameScript(this.dinosaurAppearMovie.totalFrames - 1,function():void
         {
            isClick = false;
            dinosaurFoot.removeEventListener(MouseEvent.CLICK,clickDinosaurFoot);
            dinosaurAppearMovie.stop();
            TeamSynchronizedClient.notify(showDinosaurEnd);
            addCount(1);
            dinosaurAppearMovie.buttonMode = true;
            dinosaurAppearMovie.addEventListener(MouseEvent.CLICK,clickDinosaur);
         });
         this.dinosaurAppearMovie.gotoAndPlay(2);
      }
      
      private function clickDinosaur(param1:MouseEvent) : void
      {
         if(this.isPlayingDinosaurMovie)
         {
            NewDialog.showFailMessage("你的队员还没有准备好。");
            return;
         }
         if(this.isClick)
         {
            return;
         }
         this.isClick = true;
         this.taskNpcService.showNpcPanelFreely("fbyishuzhidu3_3_helloTalk",1);
      }
      
      private function onAction(param1:TaskEvent) : void
      {
         var _loc2_:IPetFight = null;
         if(param1.params.action == "fbyishuzhidu3_3_fightDinosaur")
         {
            this.isClick = false;
            _loc2_ = ServiceContainer.getService(IPetFight) as IPetFight;
            _loc2_.fightInCopy(1);
         }
      }
      
      private function fightEnd(param1:PetFightEvent) : void
      {
         var movieClass:Class = null;
         var movie:MovieClip = null;
         var evt:PetFightEvent = param1;
         if(evt.isWin)
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
            this.dinosaurAppearMovie.removeEventListener(MouseEvent.CLICK,this.clickDinosaur);
            movieClass = FBConfig.instence.getClass("mmo.scene.fbyishuzhidu.DisappearMovie") as Class;
            movie = new movieClass() as MovieClip;
            movie.addFrameScript(movie.totalFrames - 1,function():void
            {
               movie.stop();
               ModalDialogManager.getInstance().removeModalDialog(movie);
               addCount(2);
               TeamSynchronizedClient.notify(fightEndObject);
               sceneInfo.scene.backGround.removeChild(dinosaurAppearMovie);
               var _loc1_:Class = FBConfig.instence.getClass("mmo.scene.fbyishuzhidu.PassCard") as Class;
               passCard = new _loc1_() as MovieClip;
               sceneInfo.scene.container.addChild(passCard);
               passCard.buttonMode = true;
               passCard.addEventListener(MouseEvent.CLICK,clickPassCard);
            });
            ModalDialogManager.getInstance().addModalDialog(movie,AlignType.NONE);
            movie.gotoAndPlay(1);
         }
      }
      
      private function clickPassCard(param1:MouseEvent) : void
      {
         param1.stopPropagation();
         if(this.isPlayingDisappearMovie)
         {
            NewDialog.showFailMessage("你的队员还没有准备好。");
            return;
         }
         TeamSynchronizedClient.notify(this.showPassCardBegin);
         this.showPassCardMovie();
      }
      
      private function showPassCardMovie() : void
      {
         this.passCard.removeEventListener(MouseEvent.CLICK,this.clickPassCard);
         this.passCard.addFrameScript(this.passCard.totalFrames - 1,function():void
         {
            passCard.stop();
            (sceneInfo.scene.backGround.getChildByName("door") as MovieClip).visible = true;
            TeamSynchronizedClient.notify(showPassCardEnd);
            addCount(3);
         });
         this.passCard.gotoAndPlay(2);
      }
      
      private function actionShow(param1:SocketClientEvent) : void
      {
         var _loc2_:String = param1.params.obj.customCmd;
         var _loc3_:String = param1.params.obj.teamkey;
         var _loc4_:int = int(param1.params.obj.type);
         var _loc5_:int = int(param1.params.obj.what);
         if(TeamHelper.getTeamKey() != _loc3_)
         {
            return;
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_START && _loc5_ == this.showDinosaurAction)
         {
            this.showDinosaurMovie();
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_END && _loc5_ == this.showDinosaurAction)
         {
            this.addCount(1);
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_START && _loc5_ == this.showPassCardAction)
         {
            this.showPassCardMovie();
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_END && _loc5_ == this.showPassCardAction)
         {
            this.addCount(3);
         }
         if(_loc2_ == TeamSynchronizedClient.cmdNotify && _loc4_ == FBTeamCommonTypes.TYPE_END && _loc5_ == this.fightAction)
         {
            this.addCount(2);
         }
      }
      
      private function addCount(param1:int) : void
      {
         if(param1 == 1)
         {
            ++this.count1;
         }
         else if(param1 == 2)
         {
            ++this.count2;
         }
         else if(param1 == 3)
         {
            ++this.count3;
         }
         if(TeamHelper.checkCount(this.count1))
         {
            this.isPlayingDinosaurMovie = false;
         }
         if(TeamHelper.checkCount(this.count2))
         {
            this.isPlayingDisappearMovie = false;
         }
         if(TeamHelper.checkCount(this.count3))
         {
            this.movieFinish();
            (this.sceneInfo.scene.foreGround.getChildByName("et2") as Sprite).y = (this.sceneInfo.scene.foreGround.getChildByName("et2") as Sprite).y - 500;
         }
      }
      
      public function dispose() : void
      {
         SocketClient.instance.removeEventListener(SocketClientEvent.onCustomCommand,this.actionShow);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.fightEnd);
         if(this.dinosaurFoot != null)
         {
            this.dinosaurFoot.removeEventListener(MouseEvent.CLICK,this.clickDinosaurFoot);
         }
         if(this.dinosaurAppearMovie != null)
         {
            this.dinosaurAppearMovie.removeEventListener(MouseEvent.CLICK,this.clickDinosaur);
         }
         if(this.passCard != null)
         {
            this.passCard.removeEventListener(MouseEvent.CLICK,this.clickPassCard);
         }
      }
   }
}

