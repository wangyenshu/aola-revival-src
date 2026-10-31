package mmo.fbteam.common.synchronize
{
   import mmo.fbteam.common.TeamHelper;
   import mmo.framework.comm.SocketClient;
   
   public class FBTeamSynchronizedClient
   {
      
      public function FBTeamSynchronizedClient()
      {
         super();
      }
      
      public static function notify(param1:Object) : void
      {
         param1 = null == param1 ? {} : param1;
         param1["teamkey"] = TeamHelper.getTeamKey();
         param1["un"] = SocketClient.instance.myUserName;
         SocketClient.instance.sendCustomCommand(FBTeamSynchronizedEvent.cmdNotify,param1);
         param1["customCmd"] = FBTeamSynchronizedEvent.cmdNotify;
         FBTeamSynchronizedEventDispatcher.instance.dispatchEvent(new FBTeamSynchronizedEvent(FBTeamSynchronizedEvent.cmdNotify,param1));
      }
      
      public static function notifyBack(param1:Object) : void
      {
         param1 = null == param1 ? {} : param1;
         param1["teamkey"] = TeamHelper.getTeamKey();
         param1["un"] = SocketClient.instance.myUserName;
         SocketClient.instance.sendCustomCommand(FBTeamSynchronizedEvent.cmdNotifyBack,param1);
         param1["customCmd"] = FBTeamSynchronizedEvent.cmdNotifyBack;
         FBTeamSynchronizedEventDispatcher.instance.dispatchEvent(new FBTeamSynchronizedEvent(FBTeamSynchronizedEvent.cmdNotifyBack,param1));
      }
      
      public static function finishBack(param1:Object) : void
      {
         param1 = null == param1 ? {} : param1;
         param1["teamkey"] = TeamHelper.getTeamKey();
         param1["un"] = SocketClient.instance.myUserName;
         SocketClient.instance.sendCustomCommand(FBTeamSynchronizedEvent.cmdFinishBack,param1);
         param1["customCmd"] = FBTeamSynchronizedEvent.cmdFinishBack;
         FBTeamSynchronizedEventDispatcher.instance.dispatchEvent(new FBTeamSynchronizedEvent(FBTeamSynchronizedEvent.cmdFinishBack,param1));
      }
   }
}

