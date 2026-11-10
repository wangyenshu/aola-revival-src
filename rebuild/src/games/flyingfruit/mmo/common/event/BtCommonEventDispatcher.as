package mmo.common.event
{
   public class BtCommonEventDispatcher extends AbstractBtEventDispatcher
   {
      
      public function BtCommonEventDispatcher()
      {
         super();
      }
      
      final public function destroy() : void
      {
         BtEventDispatcherManager.instance.remove(this);
         this.onDestroy();
      }
      
      protected function onDestroy() : void
      {
      }
   }
}

