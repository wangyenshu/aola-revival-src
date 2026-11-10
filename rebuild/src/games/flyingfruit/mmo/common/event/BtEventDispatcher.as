package mmo.common.event
{
   public class BtEventDispatcher extends AbstractBtEventDispatcher
   {
      
      public function BtEventDispatcher()
      {
         super();
      }
      
      final public function removeEventListeners(param1:String) : void
      {
         var _loc2_:Vector.<Function> = functions[param1] as Vector.<Function>;
         if(_loc2_ == null)
         {
            return;
         }
         var _loc3_:* = int(_loc2_.length - 1);
         while(_loc3_ >= 0)
         {
            this.removeEventListener(param1,_loc2_[_loc3_]);
            _loc3_--;
         }
      }
      
      final public function removeAllEventListeners() : void
      {
         var _loc1_:String = null;
         for(_loc1_ in functions)
         {
            this.removeEventListeners(_loc1_);
         }
      }
      
      final public function destroy() : void
      {
         this.removeAllEventListeners();
         BtEventDispatcherManager.instance.remove(this);
         this.onDestroy();
      }
      
      protected function onDestroy() : void
      {
      }
   }
}

