package mmo.play.player.dressily.mstate
{
   import mmo.interfaces.movestate.MoveStateType;

   /**
    * REBUILT: walking. The later engine adds "n" to a walking player's action
    * codes (its avatars have one set per way of moving); the 2013 avatars
    * have one set, so the code is given back as it is.
    */
   public class NormalMovingState implements IMovingState
   {
      public static const INSTANCE:NormalMovingState = new NormalMovingState();

      public function decorateAction(code:String):String
      {
         return code;
      }

      public function get moveType():String
      {
         return String(MoveStateType.WALK);
      }
   }
}
