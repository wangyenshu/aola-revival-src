package mmo.play.player.dressily.mstate
{
   import mmo.interfaces.avatar.ActionInfo;
   import mmo.interfaces.movestate.MoveStateType;

   /**
    * REBUILT: riding a 亚比 (MoveStateType.RIDE). The 2013 avatars have a riding row for
    * every action, the code ending in "r" (ActionInfo: "ddzr", "ddwr", "ddsr"): the rider
    * sits higher on it (the clothes' rows 10/11), and the ride clothes (SkinInfoForRidingPet,
    * skin/a0100xx) draw the 坐骑 only there, standing (its stand movie) or walking. So a
    * walking code ("n") becomes the riding one; others are given back as they are.
    */
   public class RidingMovingState implements IMovingState
   {
      public static const INSTANCE:RidingMovingState = new RidingMovingState();

      public function decorateAction(code:String):String
      {
         if (code == null) return code;
         if (code.length == 3) return code + "r";
         if (code.length == 4 && code.charAt(3) == "n" && ActionInfo.isStandardAction(code)) return code.substr(0, 3) + "r";
         return code;
      }

      public function get moveType():String
      {
         return String(MoveStateType.RIDE);
      }
   }
}
