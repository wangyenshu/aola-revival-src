package mmo.buddylist.buddyagent
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.buddylist.buddyagent.BuddyAgentService;

   /** REBUILT STUB locator for BuddyAgentService (module buddylist/buddyagent is lost). */
   public class BuddyAgentServiceLocator implements IServiceLocator
   {
      private static var instance:BuddyAgentService;

      public function BuddyAgentServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new BuddyAgentService();
         return instance;
      }
   }
}
