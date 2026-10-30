package mmo.msg.view
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.msg.view.MsgViewService;

   /** REBUILT STUB locator for MsgViewService (module baseservice/msgview is lost). */
   public class MsgViewServiceLocator implements IServiceLocator
   {
      private static var instance:MsgViewService;

      public function MsgViewServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new MsgViewService();
         return instance;
      }
   }
}
