package mmo.play.player.sceneplayer.observer
{
   import flash.events.Event;

   /** REBUILT (later-engine observer name): clicking a player opens the card; ScenePlayer does it here. */
   public class UserCardObserver implements IPlayerObserver
   {
      public static const NAME:String = "MyUserCardObserver";

      public function getName():String
      {
         return NAME;
      }

      public function getEventList():Array
      {
         return [];
      }

      public function getPriority():int
      {
         return 0;
      }

      public function onPlayerEvent(e:Event):void
      {
      }

      public function dispose():void
      {
      }
   }
}
