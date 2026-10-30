package mmo.play.player.sceneplayer
{
   import flash.events.MouseEvent;
   import flash.utils.Dictionary;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.play.player.dressily.Dressily;
   import mmo.play.player.dressily.IDressily;
   import mmo.play.player.movable.IMovable;
   import mmo.revival.RLog;

   /**
    * REBUILT. A player in a normal scene: new ScenePlayer(userName[, forbiddenActions]).
    * Clicking a player opens the player card (UserCardService.showUserCard), as in 2013.
    */
   public class ScenePlayer extends Player implements IMovable, IDressily
   {
      private var _forbidden:Dictionary;

      public function ScenePlayer(userName:String, forbidden:Dictionary = null, b1:Boolean = true, b2:Boolean = true)
      {
         _forbidden = forbidden;
         super(userName);
         buttonMode = true;
         addEventListener(MouseEvent.CLICK, onClickPlayer);
      }

      override protected function createDressily(forbidden:Dictionary):IDressily
      {
         return new Dressily(_forbidden, null);
      }

      protected function onClickPlayer(e:MouseEvent):void
      {
         e.stopPropagation();
         var name:String = getName();
         try
         {
            ServiceContainer.instance.tryGetService("UserCardService", function(svc:IService, o:Object):void
            {
               Object(svc).showUserCard(name, 1);
            });
         }
         catch (err:Error)
         {
            RLog.error("player card", err);
         }
      }
   }
}
