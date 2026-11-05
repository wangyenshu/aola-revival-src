package mmo.talk
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;

   /** REBUILT. The locator ServiceConfig names for TalkService: the one instance. */
   public class TalkServiceLocator implements IServiceLocator
   {
      public function TalkServiceLocator()
      {
         super();
      }

      public function getInstance():IService
      {
         return TalkService.instance;
      }
   }
}
