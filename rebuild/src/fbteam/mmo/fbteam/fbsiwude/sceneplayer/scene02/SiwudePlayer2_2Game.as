package mmo.fbteam.fbsiwude.sceneplayer.scene02
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.utils.Timer;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.fbteam.common.HitObjectHelper;
   import mmo.fbteam.common.TeamHelper;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class SiwudePlayer2_2Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private var _type:String = null;
      
      private var kills:Array = [false,false,false];
      
      private var lights:Array = [];
      
      private var ants:Array = [];
      
      private var lightsKey:Array = [];
      
      private var pit:MovieClip = null;
      
      private var pointArr:Array = [new Point(30,200),new Point(161,294),new Point(381,400)];
      
      private var curWildPetIndex:int = 0;
      
      private var timer:Timer = null;
      
      private var player:PlayerBase = null;
      
      private var pfs:IPetFight = ServiceContainer.getService(IPetFight) as IPetFight;
      
      private var taskNpcService:ITaskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      
      public function SiwudePlayer2_2Game()
      {
         super();
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         this.type = param1;
         this.player = PlayerManager.getInstance().myPlayer;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFail);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         this._type = param1;
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc5_ = this.sceneInfo.scene.foreGround.getChildByName("light_" + _loc4_) as MovieClip;
            this.lights[_loc4_] = _loc5_;
            this.lights[_loc4_].gotoAndStop(1);
            this.lightsKey[_loc4_] = 1;
            _loc6_ = this.sceneInfo.scene.foreGround.getChildByName("ant" + _loc4_) as MovieClip;
            this.ants[_loc4_] = _loc6_;
            _loc4_++;
         }
         this.pit = this.sceneInfo.scene.foreGround.getChildByName("pit") as MovieClip;
         this.gameStart();
      }
      
      private function gameStart() : void
      {
         this.timer = new Timer(40,0);
         this.timer.addEventListener(TimerEvent.TIMER,this.onTime);
         this.timer.start();
      }
      
      private function onTime(param1:TimerEvent) : void
      {
         if(TeamHelper.isCaptain())
         {
            this.checkFight();
         }
         this.checkPit();
      }
      
      private function checkLights() : void
      {
         this.checkFight();
      }
      
      private function checkFight() : void
      {
         var _loc2_:String = null;
         var _loc3_:Sprite = null;
         var _loc1_:int = 0;
         while(_loc1_ < 3)
         {
            if(!this.kills[_loc1_])
            {
               _loc2_ = "light_" + _loc1_ + "_" + "1";
               if(this.sceneInfo.scene == null || this.sceneInfo.scene.foreGround == null)
               {
                  return;
               }
               _loc3_ = this.sceneInfo.scene.foreGround.getChildByName(_loc2_) as Sprite;
               if(HitObjectHelper.hitTestObject(_loc3_,new Point(this.player.x,this.player.y)))
               {
                  this.curWildPetIndex = _loc1_;
                  MovieClip(this.ants[_loc1_]).gotoAndStop(2);
                  this.player.stop();
                  this.timer.stop();
                  this.taskNpcService.showNpcPanelFreely("fbsiwude2_beforeFight",644);
                  return;
               }
            }
            _loc1_++;
         }
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action as String;
         if(_loc2_ == "fbsiwude2_beforeFight_end")
         {
            this.fight(this.curWildPetIndex);
         }
      }
      
      private function fight(param1:int) : void
      {
         this.pfs.fightInCopy(param1 + 1);
      }
      
      private function onFail(param1:PetFightEvent) : void
      {
         TeamHelper.jumpTo(this.pointArr[this.curWildPetIndex]);
         this.timer.start();
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:MovieClip = null;
         if(param1.isWin)
         {
            _loc2_ = int(param1.id);
            this.kills[_loc2_ - 1] = true;
            _loc3_ = this.lights[_loc2_ - 1] as MovieClip;
            _loc3_.gotoAndStop(2);
            (this.ants[_loc2_ - 1] as MovieClip).gotoAndStop(3);
         }
         else
         {
            TeamHelper.jumpTo(this.pointArr[this.curWildPetIndex]);
         }
         this.timer.start();
      }
      
      private function checkAllKill() : Boolean
      {
         if(Boolean(this.kills[0]) && Boolean(this.kills[1]) && Boolean(this.kills[2]))
         {
            return true;
         }
         return false;
      }
      
      private function checkPit() : void
      {
         if(HitObjectHelper.hitTestObject(this.pit,new Point(this.player.x,this.player.y)))
         {
            this.stopTimer();
            this.player.stop();
            this.movieFinish(-1,this.type);
         }
      }
      
      private function stopTimer() : void
      {
         this.timer.stop();
         this.timer.removeEventListener(TimerEvent.TIMER,this.onTime);
      }
      
      public function dispose() : void
      {
         this.stopTimer();
         this.curWildPetIndex = 0;
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFail);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
      }
   }
}

