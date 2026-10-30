package mmo.play.flipscene.helper.player
{
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.scene.helper.player.DefaultPlayerGenerator;
   import mmo.socketserver.data.User;

   /** REBUILT. Players of an upside-down scene: as usual, with their name plates kept readable. */
   public class FlipPlayerGenerator extends DefaultPlayerGenerator
   {
      public function FlipPlayerGenerator()
      {
         super();
      }

      override public function generatePlayer(userName:String, user:User, x:int, y:int):PlayerBase
      {
         var p:ScenePlayer = super.generatePlayer(userName, user, x, y) as ScenePlayer;
         if (p != null) p.setFlip();
         return p;
      }
   }
}
