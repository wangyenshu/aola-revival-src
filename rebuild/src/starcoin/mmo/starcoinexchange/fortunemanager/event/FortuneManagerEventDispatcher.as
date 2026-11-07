package mmo.starcoinexchange.fortunemanager.event
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   
   public class FortuneManagerEventDispatcher extends EventDispatcher
   {
      
      private static var _instance:FortuneManagerEventDispatcher;
      
      public function FortuneManagerEventDispatcher(param1:IEventDispatcher = null)
      {
         super(param1);
         if(_instance != null)
         {
            throw new Error("FortuneManagerEventDispatcher error");
         }
      }
      
      public static function getInstance() : FortuneManagerEventDispatcher
      {
         if(_instance == null)
         {
            _instance = new FortuneManagerEventDispatcher();
         }
         return _instance;
      }
   }
}

