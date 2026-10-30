package mmo.play.player.sceneplayer.observer
{
   import flash.events.Event;
   import mmo.framework.comm.SocketClient;
   import mmo.play.player.movable.MovableEvent;
   import mmo.util.constants.EventListenerPriority;

   /** REBUILT. Sends my player's moves and jumps to the server (the "pt" user variable). */
   public class MyPlayerObserver implements IPlayerObserver
   {
      public static const NAME:String = "MyPlayerObserver";

      public function MyPlayerObserver()
      {
         super();
      }

      public function getName():String
      {
         return NAME;
      }

      public function getEventList():Array
      {
         return [MovableEvent.MOVE_BEGIN, MovableEvent.JUMPED];
      }

      public function getPriority():int
      {
         return EventListenerPriority.ONE;
      }

      public function onPlayerEvent(e:Event):void
      {
         var p:Object = MovableEvent(e).params;
         if (e.type == MovableEvent.MOVE_BEGIN) SocketClient.instance.move(int(p.x), int(p.y), int(p.speed));
         else if (e.type == MovableEvent.JUMPED) SocketClient.instance.jump(int(p.x), int(p.y));
      }

      public function dispose():void
      {
      }
   }
}
