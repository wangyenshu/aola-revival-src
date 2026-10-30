package mmo.pm.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.pm.search.result.Result;
   import mmo.interfaces.pet.pm.services.*;
   import mmo.interfaces.pet.pm.services.IPMSearchService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PMSearchService. Module pet/pmservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.pm.services.IPMSearchService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PMSearchService extends EventDispatcher implements IPMSearchService
   {
      public function PMSearchService()
      {
         super();
      }

      public function customAssociationId(param1:String, param2:Array, param3:uint = 10) : Array
      {
         RLog.stub("PMSearchService.customAssociationId");
         return [];
      }

      public function associationName(param1:String, param2:Boolean = true, param3:uint = 10) : Array
      {
         RLog.stub("PMSearchService.associationName");
         return [];
      }

      public function search(param1:String, param2:Boolean = true, param3:Object = null) : Result
      {
         RLog.stub("PMSearchService.search");
         return null;
      }

      public function customSearch(param1:String, param2:Array, param3:Object = null) : Result
      {
         RLog.stub("PMSearchService.customSearch");
         return null;
      }

      public function customAssociationName(param1:String, param2:Array, param3:uint = 10) : Array
      {
         RLog.stub("PMSearchService.customAssociationName");
         return [];
      }

      public function associationId(param1:String, param2:Boolean = true, param3:uint = 10) : Array
      {
         RLog.stub("PMSearchService.associationId");
         return [];
      }

      public function init() : void
      {
         RLog.stub("PMSearchService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
