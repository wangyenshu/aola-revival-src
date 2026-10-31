package mmo.fbteam.fbsiwude.sceneplayer.scene01
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.HitObjectHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.fbteam.fbsiwude.FbSiwudeCommandConst;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class FBSiwude1_3Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const petIds:Array = [1,2,3];
      
      private static const resetPoints:Array = [new Point(200,80),new Point(404,186),new Point(618,288)];
      
      private var group:Array = [{},{},{}];
      
      private var antStateTimer:Timer = null;
      
      private var fightTimer:Timer = null;
      
      private var et1:Sprite;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var ipf:IPetFight = null;
      
      private var fightIndex:int = -1;
      
      public function FBSiwude1_3Game()
      {
         super();
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:Sprite = null;
         this.type = param1;
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc5_ = this.sceneInfo.scene.container.getChildByName("ant" + _loc4_) as MovieClip;
            this.group[_loc4_].ant = _loc5_;
            this.group[_loc4_].iskill = false;
            _loc6_ = this.sceneInfo.scene.container.getChildByName("area" + _loc4_) as Sprite;
            this.group[_loc4_].area = _loc6_;
            this.group[_loc4_].isSober = _loc5_.currentFrame == 1 ? true : false;
            _loc4_++;
         }
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         this.addTimer();
      }
      
      private function addTimer() : void
      {
         this.antStateTimer = new Timer(2500,0);
         this.antStateTimer.addEventListener(TimerEvent.TIMER,this.timerFun);
         this.antStateTimer.start();
         this.fightTimer = new Timer(40,0);
         this.fightTimer.addEventListener(TimerEvent.TIMER,this.onEnterFrame);
         this.fightTimer.start();
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action as String;
         switch(_loc2_)
         {
            case "fbsiwude1_beforeFight_end":
               this.fight(this.fightIndex);
         }
      }
      
      private function timerFun(param1:TimerEvent) : void
      {
         var _loc3_:Object = null;
         var _loc2_:int = 0;
         while(_loc2_ < 3)
         {
            _loc3_ = this.group[_loc2_];
            if(null != _loc3_ && !_loc3_.iskill)
            {
               if(this.getRandomBoolean())
               {
                  MovieClip(_loc3_.ant).gotoAndStop(1);
                  _loc3_.isSober = true;
               }
               else
               {
                  MovieClip(_loc3_.ant).gotoAndStop(2);
                  _loc3_.isSober = false;
               }
            }
            _loc2_++;
         }
      }
      
      private function onEnterFrame(param1:TimerEvent) : void
      {
         var _loc4_:Object = null;
         var _loc5_:Sprite = null;
         if(!TeamHelper.isCaptain())
         {
            return;
         }
         var _loc2_:PlayerBase = PlayerManager.getInstance().myPlayer;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:int = 0;
         while(_loc3_ < 3)
         {
            _loc4_ = this.group[_loc3_];
            if(Boolean(!_loc4_.iskill) && Boolean(_loc4_.isSober) && Boolean(_loc4_.area))
            {
               _loc5_ = _loc4_.area as Sprite;
               if(HitObjectHelper.hitTestObject(_loc5_,new Point(_loc2_.x,_loc2_.y)))
               {
                  this.tryFight(_loc3_);
                  _loc2_.stop();
                  break;
               }
            }
            _loc3_++;
         }
      }
      
      private function getRandomBoolean() : Boolean
      {
         var _loc1_:Number = Math.random();
         if(_loc1_ < 0.75)
         {
            return true;
         }
         return false;
      }
      
      private function tryFight(param1:int) : void
      {
         var _loc2_:PlayerBase = PlayerManager.getInstance().myPlayer;
         _loc2_.stop();
         this.antStateTimer.stop();
         this.fightTimer.stop();
         this.taskNpcService.showNpcPanelFreely("fbsiwude1_beforeFight",644);
         PlayerManager.getInstance().myPlayer.stop();
         this.fightIndex = param1;
      }
      
      private function fight(param1:int) : void
      {
         this.ipf.fightInCopy(petIds[param1]);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc3_:Object = null;
         var _loc2_:int = int(param1.id);
         if(Boolean(param1.isWin) || Boolean(param1.isEscape))
         {
            if(param1.isWin)
            {
               _loc3_ = this.group[_loc2_ - 1];
               DisplayUtil.stopAndRemove(_loc3_.ant);
               _loc3_.ant = null;
               DisplayUtil.stopAndRemove(_loc3_.area);
               _loc3_.area = null;
               _loc3_.iskill = true;
               this.checkKills();
            }
            else if(param1.isEscape)
            {
               this.resetLoc(_loc2_);
            }
            this.fightTimer.start();
            this.antStateTimer.start();
         }
         this.fightIndex = -1;
      }
      
      private function onFightFail(param1:PetFightEvent) : void
      {
         this.resetLoc(petIds[this.fightIndex]);
         this.fightTimer.start();
         this.antStateTimer.start();
         this.fightIndex = -1;
      }
      
      private function resetLoc(param1:int) : void
      {
         var _loc2_:int = petIds.indexOf(param1);
         var _loc3_:Point = resetPoints[_loc2_] as Point;
         if(null != _loc3_)
         {
            TeamHelper.jumpTo(_loc3_);
         }
      }
      
      private function checkKills() : void
      {
         if(Boolean(this.group[0].iskill) && Boolean(this.group[1].iskill) && Boolean(this.group[2].iskill))
         {
            this.antStateTimer.stop();
            this.antStateTimer.removeEventListener(TimerEvent.TIMER,this.timerFun);
            this.fightTimer.stop();
            this.fightTimer.removeEventListener(TimerEvent.TIMER,this.onEnterFrame);
            this.movieFinish(-1,FbSiwudeCommandConst.FB1_3_GAME);
         }
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFightFail);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this.antStateTimer.stop();
         this.antStateTimer.removeEventListener(TimerEvent.TIMER,this.timerFun);
         this.fightTimer.stop();
         this.fightTimer.removeEventListener(TimerEvent.TIMER,this.onEnterFrame);
      }
   }
}

