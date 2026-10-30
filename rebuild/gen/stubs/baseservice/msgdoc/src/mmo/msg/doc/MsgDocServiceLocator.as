package mmo.msg.doc
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.msg.doc.MsgDocService;

   /** REBUILT STUB locator for MsgDocService (module baseservice/msgdoc is lost). */
   public class MsgDocServiceLocator implements IServiceLocator
   {
      private static var instance:MsgDocService;

      public function MsgDocServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new MsgDocService();
         return instance;
      }
   }
}
