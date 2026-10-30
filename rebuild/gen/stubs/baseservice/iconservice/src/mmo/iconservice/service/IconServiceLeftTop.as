package mmo.iconservice.service
{
   import mmo.interfaces.InitServiceEvent;
   import flash.display.InteractiveObject;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.geom.Point;
   import mmo.interfaces.*;
   import mmo.interfaces.IInitService;
   import mmo.interfaces.icon.*;
   import mmo.interfaces.icon.IIconService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for IconServiceLeftTop. Module baseservice/iconservice.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.icon.IIconService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class IconServiceLeftTop extends EventDispatcher implements IIconService
   {
      public function IconServiceLeftTop()
      {
         super();
      }

      public function insert(param1:String, param2:InteractiveObject, param3:Boolean, param4:int, param5:int, param6:String, param7:int, param8:int) : void
      {
         RLog.stub("IconServiceLeftTop.insert");
      }

      public function getGlobalViewCenter(param1:String) : Point
      {
         RLog.stub("IconServiceLeftTop.getGlobalViewCenter");
         return null;
      }

      public function remove(param1:String) : Boolean
      {
         RLog.stub("IconServiceLeftTop.remove");
         return false;
      }

      public function getIconByKey(param1:String) : InteractiveObject
      {
         RLog.stub("IconServiceLeftTop.getIconByKey");
         return null;
      }

      public function setAllVisable(param1:Boolean) : void
      {
         RLog.stub("IconServiceLeftTop.setAllVisable");
      }

      public function removeAll() : void
      {
         RLog.stub("IconServiceLeftTop.removeAll");
      }

      public function init() : void
      {
         RLog.stub("IconServiceLeftTop.init");
         this.dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, null));
      }

   }
}
