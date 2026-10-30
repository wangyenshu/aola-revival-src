package mmo.card
{
   import flash.display.Sprite;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import mmo.interfaces.*;
   import mmo.interfaces.ICardService;
   import mmo.revival.RLog;

   /**
    * REBUILT STUB for CardService. Module card/card.swf of January 2013 is lost;
    * this keeps the original class name and interface (mmo.interfaces.ICardService) so
    * code that looks the service up keeps running. Every method returns an
    * empty value and logs its first call.
    */
   public class DocClass extends EventDispatcher implements ICardService
   {
      public function DocClass()
      {
         super();
      }

      public function getCardView(param1:String, param2:int, param3:Number, param4:Number) : Sprite
      {
         RLog.stub("DocClass.getCardView");
         return null;
      }

      public function getCardCatalog(param1:String) : Sprite
      {
         RLog.stub("DocClass.getCardCatalog");
         return null;
      }

      public function getMultiCardCatalog(param1:String) : Sprite
      {
         RLog.stub("DocClass.getMultiCardCatalog");
         return null;
      }

      public function getNewCardCatalog(param1:String) : Sprite
      {
         RLog.stub("DocClass.getNewCardCatalog");
         return null;
      }

   }
}
