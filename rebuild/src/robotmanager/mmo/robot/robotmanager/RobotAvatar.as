package mmo.robot.robotmanager
{
   import flash.events.MouseEvent;
   import mmo.common.member.MemberManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.robot.IRobotService;
   import mmo.play.player.sceneplayer.ScenePlayer;
   import mmo.revival.RLog;

   /**
    * REBUILT after the later mmo.robot.RobotAvatar: a player's HELLO in the
    * scene, a scene player dressed in robot clothes. Its look is the one the
    * era HELLO card (robot/robotmes, RobotMesPanel.refreshHello) gives: for a
    * member his HELLO's clothes, or 40001 (skin/a300000); for everyone else
    * clothes 23 (skin/a000033, the plain HELLO). Clicking a HELLO shows its
    * card (era robot/robotanothermes); the 2013 panel of one's own HELLO
    * (robot/robotmes) survives only as a later copy, so one's own shows the
    * same card.
    */
   public class RobotAvatar extends ScenePlayer
   {
      private static const HELLO_DEFAULT:String = "23";
      private static const HELLO_MEMBER_DEFAULT:String = "40001";

      public var owner:String;

      public function RobotAvatar(owner:String)
      {
         super("hello_" + owner);
         this.owner = owner;
         setNickNameVisible(false);
      }

      /** a: the HELLO's clothes from the user variable r ("" for the default look). */
      public function setView(a:String, member:Boolean):void
      {
         var info:AvatarInfo = new AvatarInfo();
         info.setAvatarInfoWithString(member ? (a == null || a == "" ? HELLO_MEMBER_DEFAULT : a) : HELLO_DEFAULT);
         setAvatar(info);
      }

      override protected function onClickPlayer(e:MouseEvent):void
      {
         e.stopPropagation();
         try
         {
            var rs:IRobotService = ServiceContainer.getService("RobotDataService") as IRobotService;
            if (rs != null) rs.setSelectRobotId(owner);
            ServiceContainer.instance.tryGetService("RobotAnotherMes", function(svc:IService, o:Object):void
            {
               Object(svc).showPanel();
            });
         }
         catch (err:Error)
         {
            RLog.error("hello card", err);
         }
      }

      public static function isMember(name:String):Boolean
      {
         if (name != SocketClient.instance.myUserName) return false;
         try { return MemberManager.instance.isMember(); }
         catch (e:Error) {}
         return false;
      }
   }
}
