package mmo.usercard
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;

   /** REBUILT: the locator ServiceConfig names for UserCardService (created with no arguments; one card service). */
   public class UserCardServiceLocator implements IServiceLocator
   {
      private static var instance:UserCardService;

      public function UserCardServiceLocator()
      {
      }

      public function getInstance():IService
      {
         if (instance == null) instance = new UserCardService();
         return instance;
      }
   }
}
