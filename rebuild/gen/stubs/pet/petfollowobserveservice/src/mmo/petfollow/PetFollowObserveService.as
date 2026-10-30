package mmo.petfollow
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.follow.*;
   import mmo.interfaces.pet.follow.IPetFollowObserveService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for PetFollowObserveService. Module pet/petfollowobserveservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.follow.IPetFollowObserveService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class PetFollowObserveService extends EventDispatcher implements IPetFollowObserveService
   {
      private var _hasGeniusPanel:Boolean = false;
      private var _hasPanel:*;
      public function PetFollowObserveService()
      {
         super();
      }

      public function get hasGeniusPanel() : Boolean
      {
         RLog.stub("PetFollowObserveService.hasGeniusPanel");
         return this._hasGeniusPanel;
      }

      public function set hasPanel(param1:Boolean) : void
      {
         this._hasPanel = param1;
      }

      public function set hasGeniusPanel(param1:Boolean) : void
      {
         this._hasGeniusPanel = param1;
      }

      public function get hasPanel() : Boolean
      {
         RLog.stub("PetFollowObserveService.hasPanel");
         return this._hasPanel;
      }

      public function showFollowPetInfo(param1:String, param2:int, param3:Object) : void
      {
         RLog.stub("PetFollowObserveService.showFollowPetInfo");
      }

      public function init() : void
      {
         RLog.stub("PetFollowObserveService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
