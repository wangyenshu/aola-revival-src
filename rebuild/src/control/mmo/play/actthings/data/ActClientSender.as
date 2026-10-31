package mmo.play.actthings.data
{
   import flash.utils.setTimeout;
   import mmo.common.ProgressFullSprite;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;

   /**
    * REBUILT shim (not in the January 2013 engine): the later client's way to
    * send a request and wait for the reply of the same command, behind the
    * loading spinner (ProgressFullSprite). Later scenes and scripts call it
    * (崩坏的上古神殿 sends its step with it). As the live one, but the spinner
    * also goes after 8 s without a reply, so a request the revival's server
    * does not answer cannot leave the screen locked.
    */
   public class ActClientSender
   {
      public static const DEF_EXT:String = "HolidayExtension";
      public static const XT_MATERIAL:String = "MaterialExtension";

      public static function sendMessage(extension:String, cmd:String, params:Object, callback:Function, isNeedLock:Boolean = true):void
      {
         var done:Boolean = false;
         var onReply:Function = function(e:SocketClientEvent):void
         {
            SocketClient.instance.removeEventListener(cmd, onReply);
            if (!done)
            {
               done = true;
               if (isNeedLock) ProgressFullSprite.close();
            }
            if (callback != null) callback.apply(null, [e.params]);
         };
         if (isNeedLock)
         {
            ProgressFullSprite.show();
            setTimeout(function():void
            {
               if (done) return;
               done = true;
               ProgressFullSprite.close();
            }, 8000);
         }
         SocketClient.instance.addEventListener(cmd, onReply);
         sendXMessage(extension, cmd, params);
      }

      public static function sendXMessage(extension:String, cmd:String, params:Object):void
      {
         SocketClient.instance.sendXtMessage(extension, cmd, params);
      }

      public static function sendWithErrorHandle(extension:String, cmd:String, params:Object, callback:Function, isXingbi:Boolean, onError:Function = null, isNeedLock:Boolean = true):void
      {
         sendMessage(extension, cmd, params, callback, isNeedLock);
      }
   }
}
