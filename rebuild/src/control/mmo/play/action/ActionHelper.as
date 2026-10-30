package mmo.play.action
{
   import mmo.framework.comm.SocketClient;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.MovableEvent;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;

   /**
    * REBUILT (later-engine helper): play an avatar action ("lddn" sit,
    * "ddzn" stand …) on a player, mine by default. My own actions go to the
    * scene with SocketClient.sendAction ("[Action]" and the user variable
    * "action", so who comes later sees it too); walking away clears it.
    */
   public class ActionHelper
   {
      private static var _instance:ActionHelper;

      public static function get Instance():ActionHelper
      {
         if (_instance == null) _instance = new ActionHelper();
         return _instance;
      }

      public function doAction(code:String, p:PlayerBase = null, a:* = null, b:* = null, send:Boolean = true):Boolean
      {
         var who:Player = (p || PlayerManager.getInstance().myPlayer) as Player;
         if (who == null || code == null) return false;
         who.action(code);
         if (send && who == PlayerManager.getInstance().myPlayer)
         {
            SocketClient.instance.sendAction(code);
            who.removeEventListener(MovableEvent.MOVE_BEGIN, onMyMove);
            who.addEventListener(MovableEvent.MOVE_BEGIN, onMyMove);
         }
         return true;
      }

      private static function onMyMove(e:MovableEvent):void
      {
         e.currentTarget.removeEventListener(MovableEvent.MOVE_BEGIN, onMyMove);
         try { SocketClient.instance.setUserVariables({action: ""}); } catch (err:Error) {}
      }

      public function actionFragment(o:*):void
      {
      }

      public function cancleAction():void
      {
      }

      public function dispose():void
      {
      }
   }
}
