package mmo.notifyview
{
   import flash.display.Sprite;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.InitServiceEvent;

   /**
    * REBUILT baseservice/notifyview (ServiceConfig "NotifyView", IInitService).
    * The 2013 module (the strip of notices over the scene) is lost. Later
    * homes (天空之城二层, furniture/b000447) take the service as a DisplayObject
    * and hide and show it; a stand-in that is not one made them fail as the
    * player came in and left, and kept the player in the room. So it is an
    * empty Sprite that shows nothing.
    */
   public class NotifyView extends Sprite implements IInitService
   {
      public function NotifyView()
      {
         super();
         mouseEnabled = mouseChildren = false;
      }

      public function init():void
      {
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }
   }
}
