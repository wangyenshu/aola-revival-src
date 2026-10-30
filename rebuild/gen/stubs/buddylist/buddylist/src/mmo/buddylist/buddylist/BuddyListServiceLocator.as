package mmo.buddylist.buddylist
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.buddylist.buddylist.BuddyListService;

   /** REBUILT STUB locator for BuddyListService (module buddylist/buddylist is lost). */
   public class BuddyListServiceLocator implements IServiceLocator
   {
      private static var instance:BuddyListService;

      public function BuddyListServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new BuddyListService();
         return instance;
      }
   }
}
