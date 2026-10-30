package mmo.usercard
{
   import flash.events.EventDispatcher;
   import mmo.interfaces.usercard.IUserCardService;

   /**
    * REBUILT usercard/usercardservice (mmo.usercard.UserCardService): the
    * player card opened by clicking a player (showUserCard(name, tab)). In the
    * January 2013 client the card also held the wardrobe (usercard_res_clothes,
    * manifest 130124); the card art is lost, so UserCardPanel is drawn.
    */
   public class UserCardService extends EventDispatcher implements IUserCardService
   {
      private var panel:UserCardPanel;

      public function UserCardService()
      {
         super();
      }

      public function showUserCard(userName:String, tab:int = 1):void
      {
         closeUserCard();
         panel = new UserCardPanel(userName, tab);
      }

      public function closeUserCard():void
      {
         if (panel != null) panel.close();
         panel = null;
      }
   }
}
