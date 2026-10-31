package mmo.spacetime
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.ui.Mouse;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.SpacetimeClient;
   import mmo.framework.comm.SpacetimeTClient;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.spacetime.ISpacetimeService;
   import mmo.interfaces.spacetime.SpacetimeEvent;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamServiceEvent;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.scene.FBSceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.spacetime.common.BonusManager;
   import mmo.spacetime.common.ConstType;
   import mmo.spacetime.common.ControlBarManager;
   import mmo.spacetime.common.DialogHelper;
   import mmo.spacetime.common.GateManager;
   import mmo.spacetime.common.JumpSceneHelper;
   import mmo.spacetime.common.TeamHelper;
   import mmo.spacetime.number.SpacetimeNumberManager;
   
   /**
    * LATER spacetime/spacetimeservice (时空隧道), its code (a 2026 upload of the
    * service) compiled against the 2013 interfaces; the January 2013 module is
    * lost and the revival had a stand-in. The tunnel's protocol is the 2013
    * SpacetimeClient's (TowerExtension 56_*, answered by the revival's server):
    * the floor choice panel (spacetime/spacetimepanel, later) goes to a floor,
    * its rooms (spacetimefb1/2, every tenth the 时空隧道BOSS厅) hold groups of
    * 亚比 (spacetime/spacetimepet<n>); beaten all, the door opens to the next.
    * One change: the 2013 ClickAndHitHelper takes three arguments (NpcButton).
    */
   public class SpacetimeService extends EventDispatcher implements ISpacetimeService
   {
      
      private static const doorOpen:String = "door_open";
      
      private static const checkout:String = "check_Out";
      
      private static const loadScene:String = "load_scene";
      
      private var _currentUserFloor:int = 1;
      
      private var _maxUserFloor:int = 1;
      
      private var _currentUserTeamFloor:int = 1;
      
      private var _maxUserTeamFloow:int = 1;
      
      private var receId:Array = [];
      
      private var caseTrue:Boolean = false;
      
      private var _liveNpcCount:int = 0;
      
      private var backOut:Boolean = false;
      
      private var leaving:Boolean = false;
      
      private var teamService:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
      
      public function SpacetimeService()
      {
         super();
      }
      
      public function init() : void
      {
         this.addListener();
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited,{}));
      }
      
      public function get liveNpcCount() : int
      {
         return this._liveNpcCount;
      }
      
      public function set liveNpcCount(param1:int) : void
      {
         this._liveNpcCount = param1;
      }
      
      public function getMaxUserFloor() : int
      {
         return this._maxUserFloor;
      }
      
      public function getCurrentUserFloor() : int
      {
         return this._currentUserFloor;
      }
      
      public function getMaxUserTeamFloor() : int
      {
         return this._maxUserTeamFloow;
      }
      
      public function getCurrentUserTeamFloor() : int
      {
         return this._currentUserTeamFloor;
      }
      
      public function showSelectPanel() : void
      {
         // REVIVAL: the floors reached first (56_1), which the panel shows; the later
         // client had asked at login.
         var shown:Boolean = false;
         var show:Function = function(e:* = null):void
         {
            SocketClient.instance.removeEventListener(SpacetimeClient.cmdGetUserFloorInfo, show);
            if (shown) return;
            shown = true;
            DialogHelper.showSelectPanelDialog();
         };
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGetUserFloorInfo, show);
         SpacetimeClient.instence.getUserFloorInfo();
      }
      
      public function updataInfo(param1:String, param2:Function = null, ... rest) : void
      {
         switch(param1)
         {
            case doorOpen:
               GateManager.instance.openDoor();
               break;
            case checkout:
               this.checkOut();
               break;
            case loadScene:
               JumpSceneHelper.loadNextScene(rest[0],rest[1]);
         }
      }
      
      private function addListener() : void
      {
         BonusManager.instance.init();
         SocketClient.instance.addEventListener(SpacetimeClient.cmdContinueFloor,this.onlistenContinueFloor);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGoNextFloor,this.onlistenNextFloor);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGoRecordFloor,this.onlistenRecordFloor);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdLeaveTunnel,this.onlistenLeaveTunnel);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdGetUserFloorInfo,this.onlistenFloorInfo);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdCanGetCase,this.onCanGetCase);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdContinueFloor,this.onlistenContinueFloor);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdGoNextFloor,this.onlistenNextFloor);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdGoRecordFloor,this.onlistenRecordFloor);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdLeaveTunnel,this.onlistenLeaveTunnel);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdGetUserFloorInfo,this.onlistenFloorInfo);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdCanGetCase,this.onCanGetCase);
         SceneManager.getInstance().addEventListener(SceneManagerEvent.SCENE_INITED,this.onSceneInited);
         this.teamService.addEventListener(TeamServiceEvent.onLeaveTeam,this.onLeaveTeam);
      }
      
      private function resetPars() : void
      {
         this.receId = [];
         this.caseTrue = false;
         this.liveNpcCount = 0;
         this.backOut = false;
         this.leaving = false;
      }
      
      private function onSceneInited(param1:SceneManagerEvent) : void
      {
         var _loc2_:FBSceneInfo = SceneManager.getInstance().loadedSceneInfo as FBSceneInfo;
         var _loc3_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         if(null != _loc2_ && ConstType.FB_NAME == _loc2_.fbName)
         {
            SpacetimeNumberManager.Instence.tryGetNumber(this.getCurrentFloor());
            this.updataEn();
            ControlBarManager.instance.switchToSpacetimeMode();
            GateManager.instance.initGate(this.caseTrue);
            this.initMouseEffect();
         }
         else
         {
            ControlBarManager.instance.swithcToCommonMode();
            GateManager.instance.dispose();
            this.resetPars();
         }
      }
      
      private function onlistenContinueFloor(param1:SocketClientEvent) : void
      {
         this.caseTrue = param1.params.ca;
         this.analyse(param1.params.en);
         this.updataFloor(param1.params.cf);
      }
      
      private function onlistenNextFloor(param1:SocketClientEvent) : void
      {
         var _loc2_:int = int(param1.params.result);
         if(1 == _loc2_)
         {
            this.caseTrue = param1.params.ca;
            this.analyse(param1.params.en);
            this.updataFloor(param1.params.cf);
            this.tryLoadSceneByCase();
         }
         else if(-2 == _loc2_)
         {
            DialogHelper.showMaxLevelDialog();
         }
      }
      
      private function tryLoadSceneByCase() : void
      {
         if(!TeamHelper.isCaptain())
         {
            return;
         }
         JumpSceneHelper.loadNextScene(this.caseTrue,"第" + this.getCurrentFloor() + "站台");
      }
      
      private function onlistenRecordFloor(param1:SocketClientEvent) : void
      {
         this.caseTrue = param1.params.ca;
         this.analyse(param1.params.en);
         this.updataFloor(param1.params.cf);
      }
      
      private function onlistenLeaveTunnel(param1:SocketClientEvent) : void
      {
         this.backOut = true;
      }
      
      private function onlistenFloorInfo(param1:SocketClientEvent) : void
      {
         this._maxUserFloor = int(param1.params.mf);
         this._currentUserFloor = int(param1.params.cf);
         this._maxUserTeamFloow = int(param1.params.mtf);
         this._currentUserTeamFloor = int(param1.params.ctf);
      }
      
      private function onCanGetCase(param1:SocketClientEvent) : void
      {
         this.dispatchEvent(new SpacetimeEvent(SpacetimeEvent.CHECKED_CAN_GET_CASE,param1.params));
      }
      
      private function updataFloor(param1:int) : void
      {
         if(null != this.teamService.getMyTeam())
         {
            this._currentUserTeamFloor = param1;
         }
         else
         {
            this._currentUserFloor = param1;
         }
      }
      
      private function analyse(param1:Array) : void
      {
         this.receId = [];
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            this.receId.push(String(param1[_loc2_].raceId));
            _loc2_++;
         }
      }
      
      private function updataEn() : void
      {
         this.liveNpcCount = 0;
         var _loc1_:int = 0;
         while(_loc1_ < this.receId.length)
         {
            if(this.receId[_loc1_] != -1)
            {
               this.loadNpc(_loc1_,this.receId[_loc1_]);
            }
            else
            {
               this.loadNpc(_loc1_,this.receId[_loc1_]);
            }
            _loc1_++;
         }
      }
      
      private function onLeaveTeam(param1:TeamServiceEvent) : void
      {
         var _loc2_:FBSceneInfo = SceneManager.getInstance().loadedSceneInfo as FBSceneInfo;
         if(null != _loc2_ && _loc2_.fbName == ConstType.FB_NAME)
         {
            JumpSceneHelper.loadPreviousScene();
         }
      }
      
      private function loadNpc(param1:int, param2:String) : void
      {
         var _loc3_:NpcButton = new NpcButton(this.getCurrentFloor(),param1,param2);
         var _loc4_:Sprite = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("npc" + param1) as Sprite;
         _loc4_.addChild(_loc3_);
         ++this.liveNpcCount;
      }
      
      private function initMouseEffect() : void
      {
         ResScheduler.getResource("pet/wildpetservice",function(param1:Sprite):void
         {
            param1.mouseEnabled = false;
            param1.mouseChildren = false;
            param1.visible = false;
            SceneManager.getInstance().loadedSceneInfo.scene.topGround.addChild(param1);
            initMouseEvent(param1);
         },"mmo.wildpet.FightIcon");
      }
      
      private function initMouseEvent(param1:Sprite) : void
      {
         var containerAry:Array = null;
         var onOver:Function = null;
         var onOut:Function = null;
         var onRemove:Function = null;
         var container:Sprite = null;
         var fightIcon:Sprite = param1;
         containerAry = [];
         onOver = function(param1:MouseEvent):void
         {
            Mouse.hide();
            fightIcon.visible = true;
         };
         onOut = function(param1:MouseEvent):void
         {
            Mouse.show();
            fightIcon.visible = false;
         };
         onRemove = function(param1:Event):void
         {
            var _loc2_:Sprite = null;
            fightIcon.stopDrag();
            fightIcon.removeEventListener(Event.REMOVED_FROM_STAGE,onRemove);
            for each(_loc2_ in containerAry)
            {
               _loc2_.removeEventListener(MouseEvent.ROLL_OVER,onOver);
               _loc2_.removeEventListener(MouseEvent.ROLL_OUT,onOut);
            }
            containerAry.length = 0;
         };
         var i:int = 0;
         while(i < 4)
         {
            container = SceneManager.getInstance().loadedSceneInfo.scene.container.getChildByName("npc" + i) as Sprite;
            containerAry.push(container);
            container.mouseEnabled = false;
            container.addEventListener(MouseEvent.ROLL_OVER,onOver);
            container.addEventListener(MouseEvent.ROLL_OUT,onOut);
            i++;
         }
         fightIcon.addEventListener(Event.REMOVED_FROM_STAGE,onRemove);
         fightIcon.startDrag(true);
      }
      
      private function getCurrentFloor() : int
      {
         return this.teamService.getMyTeam() == null ? this._currentUserFloor : this._currentUserTeamFloor;
      }
      
      private function checkOut() : void
      {
         if(this.backOut && TeamHelper.isCaptain())
         {
            JumpSceneHelper.loadPreviousScene();
            NewDialog.showFailMessage("敌人太强大了，让我们训练更厉害的亚比再来挑战吧，很多小奥拉英雄也是经过多次挑战才获得胜利的，加油吧！");
         }
         this.backOut = false;
      }
   }
}

