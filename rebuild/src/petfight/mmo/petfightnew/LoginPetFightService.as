package mmo.petfightnew
{
   import flash.events.EventDispatcher;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetClient2;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.revival.RLog;

   /**
    * REBUILT pet/loginpetfightnew (mmo.petfightnew.LoginPetFightService,
    * IPetFight): 亚比 battles. The January 2013 module and the battle module it
    * loaded are lost; this speaks the battle part of the 2013 PetClient protocol
    * (PocketMonsterExtension: JOIN_BATTLE_JOINER 2303, START_BATTLE 2401,
    * USE_SKILL 2411, USE_ITEM 2412, SWITCH_PM 2413, ESCAPE 2414, CATCH_PM 2415,
    * STATUS_UPDATE 2421, BATTLE_NEXT_TURN 2402, BATTLE_PM_DYING 2422,
    * FIN_BATTLE 2403, PM_GAIN_EXP 2241, PM_LEVELUP 2242, PM_GAIN_NEW_SKILL
    * 2234) and shows the fight on FightPanel. Like the later service it starts
    * fights through PetClient2 (startPKWithRobot 54_2, fightWithBoss 54_16,
    * startFight 54_22) and tells the game through CommonEventDispatcher
    * (PetFightEvent FIGHT_START, FIGHT_END, ENTER_FIGHT_FAIL).
    */
   public class LoginPetFightService extends EventDispatcher implements IPetFight
   {
      private static const COMMANDS:Array = [2401, 2402, 2403, 2411, 2412, 2413, 2414, 2415, 2421, 2422, 2241, 2242, 2234];
      private var _canFight:Boolean = true;
      private var panel:FightPanel;

      public function LoginPetFightService()
      {
         super();
      }

      public function init():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener(String(PetClient.RSPN_JOIN_BATTLE_JOINER), onJoinBattle);
         for each (var c:int in COMMANDS) sc.addEventListener(String(c), onBattleCommand);
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      private function onJoinBattle(e:SocketClientEvent):void
      {
         if (e.params.msg != undefined)
         {
            if (panel == null) NewDialog.showFailMessage(String(e.params.msg));
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.ENTER_FIGHT_FAIL));
            return;
         }
         if (panel != null) panel.close();
         RLog.log("fight: joined a battle");
         panel = new FightPanel(this, e.params);
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_START, {}));
      }

      private function onBattleCommand(e:SocketClientEvent):void
      {
         if (panel != null) panel.push(int(e.type), e.params);
      }

      /** FightPanel calls this when the battle screen goes away. */
      internal function onPanelClosed(result:Object):void
      {
         panel = null;
         PetClient.instance.viewAllPM();
         PetClient.instance.loadPMMaster();
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.FIGHT_END, result));
      }

      // ---------------------------------------------------------------- IPetFight

      public function get canFight():Boolean
      {
         return _canFight;
      }

      public function set canFight(v:Boolean):void
      {
         _canFight = v;
      }

      public function isFighting():Boolean
      {
         return panel != null;
      }

      public function ifSatisfyFightCondition():Boolean
      {
         var data:IPetDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         return data == null || data.hasAvailablePet();
      }

      public function fightWithPetByRaceId(raceId:int, level:int = -1, canSwitch:Boolean = true, b:Boolean = false, id:int = -1):void
      {
         PetClient2.instance.startPKWithRobot(raceId, level, canSwitch, id);
      }

      public function fightWithTaskPet(raceId:int, level:int = -1, canSwitch:Boolean = true, b:Boolean = false, id:int = -1):void
      {
         PetClient2.instance.startPKWithRobot(raceId, level, canSwitch, id);
      }

      public function fightWithBoss(raceId:String, index:int):void
      {
         PetClient2.instance.fightWithBoss(raceId, index);
      }

      public function fightWithTeamBoss(raceId:String, index:int):void
      {
         PetClient2.instance.fightWithBoss(raceId, index);
      }

      public function startFight(type:int, canCatch:Boolean = false, params:Object = null):void
      {
         PetClient2.instance.startFight(type, params || {});
      }

      public function closeFightPanel():void
      {
         if (panel != null) panel.close();
      }

      public function fightWithOther(name:String):void
      {
         RLog.stub("LoginPetFightService.fightWithOther");
      }

      public function matchArena(b:Boolean = false):Boolean
      {
         RLog.stub("LoginPetFightService.matchArena");
         return false;
      }

      public function hurtFight(b:Boolean = false):void
      {
         RLog.stub("LoginPetFightService.hurtFight");
      }

      public function changeBackgroundRes(file:String, cls:String):void
      {
         FightPanel.backgroundOverride = [cls, file];
      }

      public function resetBackgroundRes():void
      {
         FightPanel.backgroundOverride = null;
      }

      public function timerFight(o:Object):void
      {
         RLog.stub("LoginPetFightService.timerFight");
      }

      public function showGotChallengePanel(name:String, b:Boolean):void
      {
         RLog.stub("LoginPetFightService.showGotChallengePanel");
      }

      public function fightInMagicCubic(a:int, b:int, c:Boolean):void
      {
         RLog.stub("LoginPetFightService.fightInMagicCubic");
      }

      public function insistFight(a:int, b:int, c:Boolean = false):void
      {
         RLog.stub("LoginPetFightService.insistFight");
      }

      public function handleNextFight():void
      {
      }

      public function fightWithDailyTaskPet():void
      {
         RLog.stub("LoginPetFightService.fightWithDailyTaskPet");
      }

      public function disableAutoFight():void
      {
      }

      public function enableAutoFight():void
      {
      }

      public function leaveArena():void
      {
      }

      public function autoFight():void
      {
         RLog.stub("LoginPetFightService.autoFight");
      }

      public function fightInCopy(id:int):void
      {
         PetClient2.instance.fightInCopy(id);
      }

      public function fightWithTowerPet(id:int):void
      {
         RLog.stub("LoginPetFightService.fightWithTowerPet");
      }

      public function fightInTrainingTower(a:int, b:int = 1, c:Array = null):void
      {
         RLog.stub("LoginPetFightService.fightInTrainingTower");
      }

      public function switchFightMode(mode:int, o:Object = null):void
      {
      }
   }
}
