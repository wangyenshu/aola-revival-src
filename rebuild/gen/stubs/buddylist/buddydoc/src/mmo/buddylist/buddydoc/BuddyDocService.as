package mmo.buddylist.buddydoc
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.buddy.*;
   import mmo.interfaces.buddy.IBuddyDocService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BuddyDocService. Module buddylist/buddydoc.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.buddy.IBuddyDocService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BuddyDocService extends EventDispatcher implements IBuddyDocService
   {
      private var _myUsername:String;
      public function BuddyDocService()
      {
         super();
      }

      public function sendAddBuddyRequest(param1:String, param2:Boolean = true) : *
      {
         RLog.stub("BuddyDocService.sendAddBuddyRequest");
         return null;
      }

      public function isBlock(param1:String) : Boolean
      {
         RLog.stub("BuddyDocService.isBlock");
         return false;
      }

      public function getBuddyPermissionAcceptedList() : Array
      {
         RLog.stub("BuddyDocService.getBuddyPermissionAcceptedList");
         return [];
      }

      public function removeItemFromBuddy2beMemberList(param1:String) : void
      {
         RLog.stub("BuddyDocService.removeItemFromBuddy2beMemberList");
      }

      public function getBuddyPermissionList() : Array
      {
         RLog.stub("BuddyDocService.getBuddyPermissionList");
         return [];
      }

      public function getBuddyList() : Array
      {
         RLog.stub("BuddyDocService.getBuddyList");
         return [];
      }

      public function show2beMemberPanel(param1:String) : void
      {
         RLog.stub("BuddyDocService.show2beMemberPanel");
      }

      public function getBlockList() : Array
      {
         RLog.stub("BuddyDocService.getBlockList");
         return [];
      }

      public function setBuddyGroup(param1:String, param2:int) : void
      {
         RLog.stub("BuddyDocService.setBuddyGroup");
      }

      public function getBuddy2beMemberList() : Array
      {
         RLog.stub("BuddyDocService.getBuddy2beMemberList");
         return [];
      }

      public function showBuddyRequestPanel() : void
      {
         RLog.stub("BuddyDocService.showBuddyRequestPanel");
      }

      public function isShowingBuddyRequestPanel() : Boolean
      {
         RLog.stub("BuddyDocService.isShowingBuddyRequestPanel");
         return false;
      }

      public function removeBuddy(param1:String) : void
      {
         RLog.stub("BuddyDocService.removeBuddy");
      }

      public function isOnline(param1:String) : Boolean
      {
         RLog.stub("BuddyDocService.isOnline");
         return false;
      }

      public function get myUsername() : String
      {
         RLog.stub("BuddyDocService.myUsername");
         return this._myUsername;
      }

      public function sendBuddyPermissionResponse(param1:Boolean, param2:String) : void
      {
         RLog.stub("BuddyDocService.sendBuddyPermissionResponse");
      }

      public function addBuddyAtClientOnly(param1:String) : void
      {
         RLog.stub("BuddyDocService.addBuddyAtClientOnly");
      }

      public function seedGetBuddyLocation(param1:String) : void
      {
         RLog.stub("BuddyDocService.seedGetBuddyLocation");
      }

      public function showBuddyRequestAcceptedPanel(param1:String) : void
      {
         RLog.stub("BuddyDocService.showBuddyRequestAcceptedPanel");
      }

      public function getBuddyHousesUpdateDateList() : Array
      {
         RLog.stub("BuddyDocService.getBuddyHousesUpdateDateList");
         return [];
      }

      public function removeItemFromBuddyPermissionAcceptedList(param1:String) : void
      {
         RLog.stub("BuddyDocService.removeItemFromBuddyPermissionAcceptedList");
      }

      public function setBuddyBlockStatus(param1:String, param2:Boolean) : void
      {
         RLog.stub("BuddyDocService.setBuddyBlockStatus");
      }

      public function isBuddy(param1:String) : Boolean
      {
         RLog.stub("BuddyDocService.isBuddy");
         return false;
      }

      public function checkMyBuddyQuantity() : Boolean
      {
         RLog.stub("BuddyDocService.checkMyBuddyQuantity");
         return false;
      }

      public function getUserList() : Array
      {
         RLog.stub("BuddyDocService.getUserList");
         return [];
      }

   }
}
