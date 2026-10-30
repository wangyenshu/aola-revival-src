package mmo.play.player.sceneplayer.observer
{
   import flash.events.Event;
   import mmo.interfaces.IDispose;

   /** REBUILT. Reacts to a player's events (registered with PlayerBase.registerObserver). */
   public interface IPlayerObserver extends IDispose
   {
      function onPlayerEvent(e:Event):void;
      function getName():String;
      function getEventList():Array;
      function getPriority():int;
   }
}
