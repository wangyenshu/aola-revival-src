package mmo.buddylist.buddydoc
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.buddylist.buddydoc.BuddyDocService;

   /** REBUILT STUB locator for BuddyDocService (module buddylist/buddydoc is lost). */
   public class BuddyDocServiceLocator implements IServiceLocator
   {
      private static var instance:BuddyDocService;

      public function BuddyDocServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new BuddyDocService();
         return instance;
      }
   }
}
