package mmo.antiaddiction
{
   import flash.display.DisplayObject;
   import flash.events.EventDispatcher;
   import flash.external.ExternalInterface;
   import flash.utils.getTimer;
   import mmo.interfaces.IService;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.antiaddiction.IAntiAddiction;
   import mmo.play.player.PlayerManager;
   import mmo.revival.RLog;

   /**
    * REBUILT antiaddiction/antiaddiction (ServiceConfig "AntiAddictionService"):
    * the 2012 play-time limit of China's anti-addiction rules (防沉迷), which
    * the server enforced per ID card. A private revival has no such account
    * data, so time is never used up: gathering, battles and games that ask
    * getAvailableTime() may always go ahead.
    */
   public class AntiAddictionService extends EventDispatcher implements IAntiAddiction
   {
      /**
       * The later IAntiAddiction's namespace: the 大剧院 scene that survives
       * (scene/theatre, July 2013) asks showVideo("showVideoPlayer") through
       * it, which the 2013 interface does not have.
       */
      namespace later_itf = "mmo.interfaces.antiaddiction:IAntiAddiction";

      /**
       * LATER IAntiAddiction.showVideo: the play page's JavaScript function of
       * that name shows the 百田大剧场 (the 2012 page put the 百田 video site
       * in a frame over the game, aola.js; the revival's page has its own).
       */
      later_itf function showVideo(name:String):void
      {
         try { PlayerManager.getInstance().myPlayer.stop(); } catch (e:Error) {}
         try
         {
            if (ExternalInterface.available) ExternalInterface.call(name);
         }
         catch (err:Error)
         {
            RLog.error("antiaddiction showVideo", err);
         }
      }

      private var started:int = getTimer();

      public function AntiAddictionService()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      /** Minutes of play left today. */
      public function getAvailableTime():int
      {
         return 300;
      }

      public function start(view:DisplayObject):void
      {
      }

      public function isOverHalfTime():Boolean
      {
         return false;
      }

      public function pause():void
      {
      }

      /** Minutes since the game started. */
      public function getLoginTime():int
      {
         return int((getTimer() - started) / 60000);
      }

      public function resume():void
      {
      }

      public function isHoliday():Boolean
      {
         var d:int = new Date().day;
         return d == 0 || d == 6;
      }
   }
}
