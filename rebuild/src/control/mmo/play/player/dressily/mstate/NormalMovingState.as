package mmo.play.player.dressily.mstate
{
   import mmo.interfaces.movestate.MoveStateType;

   /**
    * REBUILT: walking. An action's code ends in the way of moving (2013 ActionInfo: "n"
    * walking, "f" flying, "r" riding: "ddzn", "ddzr"); a code of three letters gets the
    * walking "n", a whole one is given back as it is.
    */
   public class NormalMovingState implements IMovingState
   {
      public static const INSTANCE:NormalMovingState = new NormalMovingState();

      public function decorateAction(code:String):String
      {
         return code != null && code.length == 3 ? code + "n" : code;
      }

      public function get moveType():String
      {
         return String(MoveStateType.WALK);
      }
   }
}
