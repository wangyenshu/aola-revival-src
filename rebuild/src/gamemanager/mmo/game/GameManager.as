package mmo.game
{
   import flash.events.EventDispatcher;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.game.common.GameEntrance;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.game.GameTable;
   import mmo.interfaces.game.IGameManager;
   import mmo.interfaces.team.ITeamService;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.SceneManager;

   /**
    * REBUILT game/gamemanager (GameManager, IGameManager): the 2013 module is
    * lost; this is the later one (2015, decompiled) on the 2013 interfaces.
    * showGame(id) shows the game's entrance panel (gameentrancepanel/*, era
    * files) and its OK button loads the game; loadGame(id) goes to the game
    * (SceneManager.loadGame of its GameTable room); score2money sends the
    * score (SocketClient.endGame: ScoreManager.increaseScore).
    */
   public class GameManager extends EventDispatcher implements IGameManager
   {
      private var isGameEntranceShowing:Boolean = false;

      /**
       * Games of the later GameTable (after the 2013 one's 61) whose buttons the
       * later scene copies carry: their rooms (the revival's config.xml).
       */
      public static const LATER_GAMES:Object = {64: "gameLimitBomb", 66: "gameNinjaRush"};

      public static function sceneOf(id:int):String
      {
         return GameTable.getSceneNameByGameId(id) || LATER_GAMES[id];
      }

      public function GameManager()
      {
         super();
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function getGameEntrancePanel(id:int):void
      {
      }

      public function showGame(id:int, ext:Object = null):void
      {
         if (isGameEntranceShowing) return;
         if (!checkCan())
         {
            NewDialog.showSucceedMessage("对不起，组队状态不能进行游戏!");
            return;
         }
         isGameEntranceShowing = true;
         try { PlayerManager.getInstance().myPlayer.stop(); } catch (e:Error) {}
         new GameEntrance(id, this, ext).tryShowPanel();
      }

      public function cancelGameKey():void
      {
         isGameEntranceShowing = false;
      }

      public function loadGame(id:int, ext:Object = null):void
      {
         if (!checkCan())
         {
            NewDialog.showSucceedMessage("对不起，组队状态不能进行游戏!");
            return;
         }
         var scene:String = sceneOf(id);
         if (scene != null && scene != "") SceneManager.getInstance().loadGame(scene, true, ext);
      }

      public function unloadGame():void
      {
         if (SceneManager.getInstance().loadedGameInfo != null) SceneManager.getInstance().unloadGame();
      }

      public function score2money(id:int, score:int, level:int = 1, drop:Boolean = true):void
      {
         var scene:String = sceneOf(id);
         if (scene != null && scene != "") SocketClient.instance.endGame(score, level, drop, scene);
      }

      private function checkCan():Boolean
      {
         var team:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         try { return team == null || team.getMyTeam() == null; } catch (e:Error) {}
         return true;
      }
   }
}
