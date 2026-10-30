package mmo.play.scene.helper.player
{
   import flash.utils.Dictionary;
   import mmo.common.member.MemberTypes;
   import mmo.framework.comm.SocketClient;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.play.player.sceneplayer.observer.MyPlayerObserver;
   import mmo.socketserver.data.User;

   /**
    * REBUILT. The ordinary player of a scene, built the way the surviving
    * arena generator (robarena) builds its own: avatar from the "avatar" user
    * variable, mouse control and the server observer for me, the current
    * action for others, nickname "nn", member format by "mtype".
    */
   public class DefaultPlayerGenerator implements IPlayerGenerator
   {
      public function DefaultPlayerGenerator()
      {
         super();
      }

      public function getForbiddenAction():Dictionary
      {
         return null;
      }

      public function generatePlayer(userName:String, user:User, x:int, y:int):PlayerBase
      {
         var p:ScenePlayer = new ScenePlayer(userName, getForbiddenAction());
         if (user != null) p.setAvatar(user.getVariable("avatar"));
         if (userName == SocketClient.instance.myUserName)
         {
            p.setStrategy(new MouseControlStrategy());
            p.registerObserver(new MyPlayerObserver());
            p.addSelfSymbol();
         }
         else if (user != null)
         {
            var act:String = user.getVariable("action") as String;
            if (act != null && act.length > 0) p.action(act);
         }
         if (user != null)
         {
            var nn:* = user.getVariable("nn");
            if (nn) p.setNickName(String(nn));
            if (MemberTypes.compareMemberType(int(user.getVariable("mtype")), MemberTypes.Member)) p.initMemberFormat();
         }
         p.jumpTo(x, y);
         return p;
      }
   }
}
