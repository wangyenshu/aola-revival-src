package mmo.fbteam.fbsiwude.sceneplayer.scene03
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.fbteam.auto.IScenePlayerStep;
   import mmo.fbteam.auto.ScenePlayerStepBase;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   
   public class FBSiwude3_2Game extends ScenePlayerStepBase implements IScenePlayerStep
   {
      
      private static const petIds:Array = [1,2,3];
      
      private static const npcTalks:Array = ["fbsiwude3_645_beforeFight_1","fbsiwude3_645_beforeFight_2","fbsiwude3_645_beforeFight_3"];
      
      private static const npcFailTalks:Array = ["fbsiwude3_fightend_fail_645_1","fbsiwude3_fightend_fail_645_2","fbsiwude3_fightend_fail_645_3"];
      
      private var npcViews:Array = [];
      
      private var doors:Array = [];
      
      private var obs:Array = [];
      
      private var fightIndex:int = -1;
      
      private var taskNpcService:ITaskNpcService = null;
      
      private var ipf:IPetFight = null;
      
      private var fightedCount:int = 0;
      
      public function FBSiwude3_2Game()
      {
         super();
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
         this.ipf = ServiceContainer.getService(IPetFight) as IPetFight;
      }
      
      public function run(param1:String, param2:Function = null, param3:Object = null) : void
      {
         this.type = param1;
         this.initPars();
         this.initFuns();
      }
      
      private function initPars() : void
      {
         var _loc5_:MovieClip = null;
         var _loc6_:DisplayObject = null;
         var _loc7_:MovieClip = null;
         var _loc1_:DisplayObjectContainer = this.sceneInfo.scene.backGround;
         var _loc2_:DisplayObjectContainer = this.sceneInfo.scene.obStruction;
         var _loc3_:DisplayObjectContainer = this.sceneInfo.scene.container;
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc5_ = _loc1_.getChildByName("door_" + _loc4_) as MovieClip;
            this.doors.push(_loc5_);
            _loc6_ = _loc2_.getChildByName("ob_" + _loc4_) as DisplayObject;
            this.obs.push(_loc6_);
            _loc7_ = _loc3_.getChildByName("npc_" + _loc4_) as MovieClip;
            _loc7_.mouseChildren = false;
            this.npcViews.push(_loc7_);
            _loc4_++;
         }
      }
      
      private function initFuns() : void
      {
         var _loc1_:MovieClip = null;
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         for each(_loc1_ in this.npcViews)
         {
            _loc1_.buttonMode = true;
            ClickAndHitHelper.instance.registerTarget(_loc1_,true);
            _loc1_.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickAndHit);
         }
      }
      
      private function onClickAndHit(param1:ClickAndHitEvent) : void
      {
         param1.stopImmediatePropagation();
         var _loc2_:MovieClip = param1.currentTarget as MovieClip;
         var _loc3_:int = this.npcViews.indexOf(_loc2_);
         this.fightIndex = _loc3_;
         this.taskNpcService.showNpcPanelFreely(npcTalks[_loc3_],645);
         PlayerManager.getInstance().myPlayer.stop();
      }
      
      private function onTaskAction(param1:TaskEvent) : void
      {
         var _loc2_:String = param1.params.action;
         switch(_loc2_)
         {
            case "fbsiwude3_645_beforeFight_1end":
            case "fbsiwude3_645_beforeFight_2end":
            case "fbsiwude3_645_beforeFight_3end":
               this.fight(this.fightIndex);
         }
      }
      
      private function fight(param1:int) : void
      {
         this.ipf.fightInCopy(petIds[param1]);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         var _loc2_:int = int(param1.id);
         var _loc3_:int = petIds.indexOf(_loc2_);
         if(param1.isWin)
         {
            ++this.fightedCount;
            this.killNpc(_loc3_);
            this.openDoor(_loc3_);
         }
         else
         {
            this.taskNpcService.showNpcPanelFreely(npcFailTalks[_loc3_],645);
         }
      }
      
      private function openDoor(param1:int) : void
      {
         var mc:MovieClip = null;
         var index:int = param1;
         mc = this.doors[index] as MovieClip;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(obs[index]);
            sceneInfo.scene.setMapArray();
            checkFinish();
            mc.stop();
         });
         mc.gotoAndPlay(2);
      }
      
      private function killNpc(param1:int) : void
      {
         var _loc2_:MovieClip = this.npcViews[param1] as MovieClip;
         if(null == _loc2_)
         {
            return;
         }
         _loc2_.buttonMode = false;
         ClickAndHitHelper.instance.remove(_loc2_);
         _loc2_.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickAndHit);
         DisplayUtil.stopAndRemove(_loc2_);
      }
      
      private function checkFinish() : void
      {
         if(this.fightedCount >= 3)
         {
            this.movieFinish(-1,this.type);
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < 3)
         {
            this.killNpc(_loc1_);
            _loc1_++;
         }
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onTaskAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
   }
}

