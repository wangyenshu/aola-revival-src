package mmo.game
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.game.*;
   import mmo.interfaces.game.IGameManager;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for GameManager. Module game/gamemanager.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.game.IGameManager) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class GameManager extends EventDispatcher implements IGameManager
   {
      public function GameManager()
      {
         super();
      }

      public function score2money(param1:int, param2:int, param3:int = 1, param4:Boolean = true) : void
      {
         RLog.stub("GameManager.score2money");
      }

      public function unloadGame() : void
      {
         RLog.stub("GameManager.unloadGame");
      }

      public function getGameEntrancePanel(param1:int) : void
      {
         RLog.stub("GameManager.getGameEntrancePanel");
      }

      public function loadGame(param1:int, param2:Object = null) : void
      {
         RLog.stub("GameManager.loadGame");
      }

      public function showGame(param1:int, param2:Object = null) : void
      {
         RLog.stub("GameManager.showGame");
      }

      public function init() : void
      {
         RLog.stub("GameManager.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
