package mmo.petfightnew
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.fight.*;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetFightService. Module pet/loginpetfightnew.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.fight.IPetFight) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class LoginPetFightService extends EventDispatcher implements IPetFight
   {
      private var _canFight:*;
      public function LoginPetFightService()
      {
         super();
      }

      public function set canFight(param1:Boolean) : void
      {
         this._canFight = param1;
      }

      public function fightWithOther(param1:String) : void
      {
         RLog.stub("LoginPetFightService.fightWithOther");
      }

      public function matchArena(param1:Boolean = false) : Boolean
      {
         RLog.stub("LoginPetFightService.matchArena");
         return false;
      }

      public function fightWithBoss(param1:String, param2:int) : void
      {
         RLog.stub("LoginPetFightService.fightWithBoss");
      }

      public function fightWithTaskPet(param1:int, param2:int = -1, param3:Boolean = true, param4:Boolean = false, param5:int = -1) : void
      {
         RLog.stub("LoginPetFightService.fightWithTaskPet");
      }

      public function fightWithTeamBoss(param1:String, param2:int) : void
      {
         RLog.stub("LoginPetFightService.fightWithTeamBoss");
      }

      public function hurtFight(param1:Boolean = false) : void
      {
         RLog.stub("LoginPetFightService.hurtFight");
      }

      public function changeBackgroundRes(param1:String, param2:String) : void
      {
         RLog.stub("LoginPetFightService.changeBackgroundRes");
      }

      public function resetBackgroundRes() : void
      {
         RLog.stub("LoginPetFightService.resetBackgroundRes");
      }

      public function timerFight(param1:Object) : void
      {
         RLog.stub("LoginPetFightService.timerFight");
      }

      public function startFight(param1:int, param2:Boolean = false, param3:Object = null) : void
      {
         RLog.stub("LoginPetFightService.startFight");
      }

      public function showGotChallengePanel(param1:String, param2:Boolean) : void
      {
         RLog.stub("LoginPetFightService.showGotChallengePanel");
      }

      public function ifSatisfyFightCondition() : Boolean
      {
         RLog.stub("LoginPetFightService.ifSatisfyFightCondition");
         return false;
      }

      public function fightInMagicCubic(param1:int, param2:int, param3:Boolean) : void
      {
         RLog.stub("LoginPetFightService.fightInMagicCubic");
      }

      public function insistFight(param1:int, param2:int, param3:Boolean = false) : void
      {
         RLog.stub("LoginPetFightService.insistFight");
      }

      public function handleNextFight() : void
      {
         RLog.stub("LoginPetFightService.handleNextFight");
      }

      public function fightWithDailyTaskPet() : void
      {
         RLog.stub("LoginPetFightService.fightWithDailyTaskPet");
      }

      public function disableAutoFight() : void
      {
         RLog.stub("LoginPetFightService.disableAutoFight");
      }

      public function isFighting() : Boolean
      {
         RLog.stub("LoginPetFightService.isFighting");
         return false;
      }

      public function enableAutoFight() : void
      {
         RLog.stub("LoginPetFightService.enableAutoFight");
      }

      public function leaveArena() : void
      {
         RLog.stub("LoginPetFightService.leaveArena");
      }

      public function get canFight() : Boolean
      {
         RLog.stub("LoginPetFightService.canFight");
         return this._canFight;
      }

      public function autoFight() : void
      {
         RLog.stub("LoginPetFightService.autoFight");
      }

      public function fightInCopy(param1:int) : void
      {
         RLog.stub("LoginPetFightService.fightInCopy");
      }

      public function fightWithTowerPet(param1:int) : void
      {
         RLog.stub("LoginPetFightService.fightWithTowerPet");
      }

      public function fightWithPetByRaceId(param1:int, param2:int = -1, param3:Boolean = true, param4:Boolean = false, param5:int = -1) : void
      {
         RLog.stub("LoginPetFightService.fightWithPetByRaceId");
      }

      public function fightInTrainingTower(param1:int, param2:int = 1, param3:Array = null) : void
      {
         RLog.stub("LoginPetFightService.fightInTrainingTower");
      }

      public function closeFightPanel() : void
      {
         RLog.stub("LoginPetFightService.closeFightPanel");
      }

      public function switchFightMode(param1:int, param2:Object = null) : void
      {
         RLog.stub("LoginPetFightService.switchFightMode");
      }

      public function init() : void
      {
         RLog.stub("LoginPetFightService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
