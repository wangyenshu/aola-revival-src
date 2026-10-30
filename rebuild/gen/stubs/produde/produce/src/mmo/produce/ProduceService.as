package mmo.produce
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.produce.*;
   import mmo.interfaces.produce.IProduceService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for ProduceService. Module produde/produce.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.produce.IProduceService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class ProduceService extends EventDispatcher implements IProduceService
   {
      public function ProduceService()
      {
         super();
      }

      public function showProduceDialog(param1:int) : void
      {
         RLog.stub("ProduceService.showProduceDialog");
      }

   }
}
