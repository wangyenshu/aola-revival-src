package mmo.faceservice
{
   import flash.display.MovieClip;
   import flash.events.EventDispatcher;
   import flash.system.ApplicationDomain;
   import mmo.interfaces.face.IFaceService;

   /**
    * REBUILT baseservice/face (ServiceConfig "FaceService", IFaceService):
    * the faces (表情) players show over their heads. The 2013 module is lost.
    * The face pictures are the HELLO faces mmo.faceservice.face1 … of the
    * later copy of this module, whose faces 1–22 are its "old" faces (its
    * getFaceIds() still lists 1–22; 23 and up came later with items), put
    * into this module by build/all.sh. getFace hands back a new MovieClip of
    * the face, stopped on its first frame, as the later module does.
    */
   public class FaceService extends EventDispatcher implements IFaceService
   {
      private static const PREFIX:String = "mmo.faceservice.face";
      private static const COUNT:int = 22;

      public function FaceService()
      {
         super();
      }

      public function getFace(faceId:int, callback:Function, thisObject:* = null):void
      {
         var mc:MovieClip = null;
         var name:String = PREFIX + faceId;
         try
         {
            if (ApplicationDomain.currentDomain.hasDefinition(name))
            {
               var C:Class = ApplicationDomain.currentDomain.getDefinition(name) as Class;
               mc = new C() as MovieClip;
               if (mc) mc.gotoAndStop(1);
            }
         }
         catch (e:Error) {}
         if (callback != null) callback.apply(thisObject, [faceId, mc]);
      }

      public function getFaceIds():Array
      {
         var ids:Array = [];
         for (var i:int = 1; i <= COUNT; i++) ids.push(i);
         return ids;
      }
   }
}
