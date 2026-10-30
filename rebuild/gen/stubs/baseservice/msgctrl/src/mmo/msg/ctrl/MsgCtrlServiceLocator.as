package mmo.msg.ctrl
{
   import mmo.interfaces.IService;
   import mmo.interfaces.IServiceLocator;
   import mmo.msg.ctrl.MsgCtrlService;

   /** REBUILT STUB locator for MsgCtrlService (module baseservice/msgctrl is lost). */
   public class MsgCtrlServiceLocator implements IServiceLocator
   {
      private static var instance:MsgCtrlService;

      public function MsgCtrlServiceLocator()
      {
      }

      public function getInstance() : IService
      {
         if (instance == null) instance = new MsgCtrlService();
         return instance;
      }
   }
}
