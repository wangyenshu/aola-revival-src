package mmo.play.player.dressily.mstate
{
   /**
    * REBUILT after the later engine: how a player moves (walking, riding,
    * flying) and what that does to an action's code. Later scene code asks
    * IDressily.getMovingState().decorateAction(code) before playing one
    * (十字大道's 升降机).
    */
   public interface IMovingState
   {
      function decorateAction(code:String):String;
      function get moveType():String;
   }
}
