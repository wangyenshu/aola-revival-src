package mmo.usercard
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.usercard.UserCardService;

   /** REBUILT STUB locator for UserCardService (module usercard/usercardservice is lost). */
   public class UserCardServiceLocator implements IServiceLocator
   {
      private static var instance:UserCardService;

      public function UserCardServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new UserCardService();
         return instance;
      }
   }
}
