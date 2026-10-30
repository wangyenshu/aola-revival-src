package mmo.reader
{
   import flash.events.EventDispatcher;
   import flash.net.SharedObject;
   import mmo.interfaces.InitServiceEvent;
   import mmo.interfaces.catalog.IBconfigReaderService;

   /**
    * REBUILT catalog/bconfigreaderservice (mmo.reader.BconfigReaderService):
    * loads the book list and remembers which books the player has opened
    * since they last changed (the "new" marks), in a local shared object.
    */
   public class BconfigReaderService extends EventDispatcher implements IBconfigReaderService
   {
      public function BconfigReaderService()
      {
         super();
      }

      public function init():void
      {
         BConfigReader.instence.loadConfig();
         dispatchEvent(new InitServiceEvent(InitServiceEvent.onInited, {}));
      }

      public function isRead(no:String):Boolean
      {
         try
         {
            var so:SharedObject = SharedObject.getLocal("aolaRevivalBooks", "/");
            return so.data[no] == BConfigReader.instence.getUpdateItem(no).value;
         }
         catch (e:Error) {}
         return true;
      }

      public function setRead(no:String):void
      {
         try
         {
            var so:SharedObject = SharedObject.getLocal("aolaRevivalBooks", "/");
            so.data[no] = BConfigReader.instence.getUpdateItem(no).value;
            so.flush();
         }
         catch (e:Error) {}
      }
   }
}
