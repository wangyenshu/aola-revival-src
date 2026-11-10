package mmo.common.event
{
   import flash.events.EventDispatcher;
   
   internal class AbstractBtEventDispatcher extends EventDispatcher implements IEventMonitor
   {
      
      protected var functions:Object = {};
      
      public function AbstractBtEventDispatcher()
      {
         super();
         BtEventDispatcherManager.instance.register(this);
      }
      
      final override public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         if(param3)
         {
            throw new Error("Event has not capture phase except displayObject");
         }
         super.addEventListener(param1,param2,param3,param4,param5);
         if(param5)
         {
            return;
         }
         var _loc6_:Vector.<Function> = this.functions[param1] as Vector.<Function>;
         if(_loc6_ == null)
         {
            _loc6_ = new Vector.<Function>();
            this.functions[param1] = _loc6_;
         }
         _loc6_.push(param2);
      }
      
      final override public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         super.removeEventListener(param1,param2,param3);
         var _loc4_:Vector.<Function> = this.functions[param1] as Vector.<Function>;
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:int = _loc4_.indexOf(param2);
         if(_loc5_ < 0)
         {
            return;
         }
         _loc4_.splice(_loc5_,1);
         if(_loc4_.length == 0)
         {
            delete this.functions[param1];
         }
      }
      
      final public function getAllListenersCountString() : String
      {
         var _loc3_:String = null;
         var _loc1_:String = "";
         var _loc2_:Boolean = true;
         for(_loc3_ in this.functions)
         {
            if(!_loc2_)
            {
               _loc1_ += "\n";
            }
            else
            {
               _loc2_ = false;
            }
            _loc1_ += _loc3_ + ":" + this.getListenersCount(_loc3_);
         }
         return this + ":\n" + _loc1_;
      }
      
      final public function getListenersCount(param1:String) : int
      {
         var _loc2_:Vector.<Function> = this.functions[param1] as Vector.<Function>;
         if(_loc2_ == null)
         {
            return -1;
         }
         return _loc2_.length;
      }
      
      final public function getAllListenersCount() : Object
      {
         var _loc2_:String = null;
         var _loc1_:Object = {};
         for(_loc2_ in this.functions)
         {
            _loc1_[_loc2_] = this.getListenersCount(_loc2_);
         }
         return _loc1_;
      }
   }
}

