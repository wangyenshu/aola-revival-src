package mmo.usercard
{
   import mmo.play.player.PlayerManager;

   /** The player object of the rebuilt engine, for the nickname. */
   public class PlayerManagerRef
   {
      public static function myPlayer():Object
      {
         return PlayerManager.getInstance().myPlayer;
      }
   }
}
