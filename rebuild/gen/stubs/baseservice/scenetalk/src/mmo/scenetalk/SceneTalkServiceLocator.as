package mmo.scenetalk
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.scenetalk.SceneTalkService;

   /** REBUILT STUB locator for SceneTalkService (module baseservice/scenetalk is lost). */
   public class SceneTalkServiceLocator implements IServiceLocator
   {
      private static var instance:SceneTalkService;

      public function SceneTalkServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new SceneTalkService();
         return instance;
      }
   }
}
