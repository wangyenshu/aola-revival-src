package mmo.scenetalk
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;

   /** REBUILT. The locator ServiceConfig names for SceneTalkService: one shared instance. */
   public class SceneTalkServiceLocator implements IServiceLocator
   {
      private static var service:SceneTalkService;

      public function SceneTalkServiceLocator()
      {
         super();
      }

      public function getInstance():IService
      {
         if (service == null) service = new SceneTalkService();
         return service;
      }
   }
}
