package mmo.talk
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.talk.TalkService;

   /** REBUILT STUB locator for TalkService (module talk/talk is lost). */
   public class TalkServiceLocator implements IServiceLocator
   {
      private static var instance:TalkService;

      public function TalkServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new TalkService();
         return instance;
      }
   }
}
