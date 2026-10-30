package mmo.play.scene.helper.player
{
   import flash.utils.Dictionary;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.socketserver.data.User;

   /** REBUILT. Builds the player object for each user in a room (scenes may supply their own). */
   public interface IPlayerGenerator
   {
      function getForbiddenAction():Dictionary;
      function generatePlayer(userName:String, user:User, x:int, y:int):PlayerBase;
   }
}
