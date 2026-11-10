package mmo.common.event
{
   public class BtEventDispatcherManager
   {
      
      internal static const instance:BtEventDispatcherManager = new BtEventDispatcherManager();
      
      private var dispatchers:Vector.<IEventMonitor> = new Vector.<IEventMonitor>();
      
      public function BtEventDispatcherManager()
      {
         super();
      }
      
      public static function getDispatchers() : Vector.<IEventMonitor>
      {
         return instance.dispatchers.concat();
      }
      
      public static function getllListenersCountString() : String
      {
         var _loc2_:String = null;
         var _loc3_:IEventMonitor = null;
         var _loc1_:String = "";
         for(_loc2_ in instance.dispatchers)
         {
            _loc3_ = instance.dispatchers[_loc2_] as IEventMonitor;
            _loc1_ += _loc3_.getAllListenersCountString() + "\n";
         }
         return _loc1_;
      }
      
      internal function register(param1:IEventMonitor) : void
      {
         this.dispatchers.push(param1);
      }
      
      internal function remove(param1:IEventMonitor) : void
      {
         var _loc2_:int = this.dispatchers.indexOf(param1);
         if(_loc2_ < 0)
         {
            return;
         }
         this.dispatchers.splice(_loc2_,1);
      }
   }
}

