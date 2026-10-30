package mmo.family.bulletinboard
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.family.*;
   import mmo.interfaces.family.IBulletinBoardService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for BulletinBoardService. Module family/bulletinboard.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.family.IBulletinBoardService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class BulletinBoardService extends EventDispatcher implements IBulletinBoardService
   {
      public function BulletinBoardService()
      {
         super();
      }

      public function showBulletinBoard(param1:int) : void
      {
         RLog.stub("BulletinBoardService.showBulletinBoard");
      }

   }
}
