package mmo.faceservice
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.IService;
   import mmo.interfaces.face.*;
   import mmo.interfaces.face.IFaceService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for FaceService. Module baseservice/face.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.face.IFaceService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class FaceService extends EventDispatcher implements IFaceService
   {
      public function FaceService()
      {
         super();
      }

      public function getFace(param1:int, param2:Function, param3:* = null) : void
      {
         RLog.stub("FaceService.getFace");
      }

      public function getFaceIds() : Array
      {
         RLog.stub("FaceService.getFaceIds");
         return [];
      }

   }
}
