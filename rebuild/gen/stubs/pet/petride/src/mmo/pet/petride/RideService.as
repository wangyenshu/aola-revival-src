package mmo.pet.petride
{
   import mmo.interfaces.InitServiceEvent;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.ride.*;
   import mmo.interfaces.pet.ride.IRideService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for RideService. Module pet/petride.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.pet.ride.IRideService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class RideService extends EventDispatcher implements IRideService
   {
      private var _getMyRidePetId:int = 0;
      private var _rideServieIsEffect:Boolean = false;
      private var _getOtherRidePetId:int = 0;
      private var _isClientRide:Boolean = false;
      public function RideService()
      {
         super();
      }

      public function get getMyRidePetId() : int
      {
         RLog.stub("RideService.getMyRidePetId");
         return this._getMyRidePetId;
      }

      public function validateRidePetRace() : Array
      {
         RLog.stub("RideService.validateRidePetRace");
         return [];
      }

      public function clientRide(param1:PetBriefInfo) : void
      {
         RLog.stub("RideService.clientRide");
      }

      public function get rideServieIsEffect() : Boolean
      {
         RLog.stub("RideService.rideServieIsEffect");
         return this._rideServieIsEffect;
      }

      public function get getOtherRidePetId() : int
      {
         RLog.stub("RideService.getOtherRidePetId");
         return this._getOtherRidePetId;
      }

      public function hasRideCard() : Boolean
      {
         RLog.stub("RideService.hasRideCard");
         return false;
      }

      public function set rideServieIsEffect(param1:Boolean) : void
      {
         this._rideServieIsEffect = param1;
      }

      public function cardIsEffect() : Boolean
      {
         RLog.stub("RideService.cardIsEffect");
         return false;
      }

      public function get isClientRide() : Boolean
      {
         RLog.stub("RideService.isClientRide");
         return this._isClientRide;
      }

      public function unRide(param1:PetBriefInfo) : void
      {
         RLog.stub("RideService.unRide");
      }

      public function validatePetIsTranning(param1:PetBriefInfo) : Boolean
      {
         RLog.stub("RideService.validatePetIsTranning");
         return false;
      }

      public function validatePetRideLevelEnough(param1:PetBriefInfo) : Boolean
      {
         RLog.stub("RideService.validatePetRideLevelEnough");
         return false;
      }

      public function validateRideReady(param1:PetBriefInfo) : Boolean
      {
         RLog.stub("RideService.validateRideReady");
         return false;
      }

      public function trainPet(param1:PetBriefInfo) : void
      {
         RLog.stub("RideService.trainPet");
      }

      public function ride(param1:PetBriefInfo) : void
      {
         RLog.stub("RideService.ride");
      }

      public function rideToWalk() : void
      {
         RLog.stub("RideService.rideToWalk");
      }

      public function init() : void
      {
         RLog.stub("RideService.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
