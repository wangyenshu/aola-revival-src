package mmo.util.command
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   
   public class SceneSimpleCommand implements ISceneCommand, IEventDispatcher
   {
      
      private var _eventDispatcher:EventDispatcher;
      
      public function SceneSimpleCommand()
      {
         super();
         this._eventDispatcher = new EventDispatcher();
      }
      
      public function execute(param1:Object) : void
      {
      }
      
      public function cancel() : void
      {
         this.dispatchEvent(new SceneCommandEvent(SceneCommandEvent.CANCELED,this));
      }
      
      public function addEventListener(param1:String, param2:Function, param3:Boolean = false, param4:int = 0, param5:Boolean = false) : void
      {
         this._eventDispatcher.addEventListener(param1,param2,param3,param4,param5);
      }
      
      public function removeEventListener(param1:String, param2:Function, param3:Boolean = false) : void
      {
         this._eventDispatcher.removeEventListener(param1,param2,param3);
      }
      
      public function dispatchEvent(param1:Event) : Boolean
      {
         return this._eventDispatcher.dispatchEvent(param1);
      }
      
      public function hasEventListener(param1:String) : Boolean
      {
         return this._eventDispatcher.hasEventListener(param1);
      }
      
      public function willTrigger(param1:String) : Boolean
      {
         return this._eventDispatcher.willTrigger(param1);
      }
      
      final protected function succeed(param1:Object) : void
      {
         this.dispatchEvent(new SceneCommandEvent(SceneCommandEvent.SUCCEED,this,param1));
      }
      
      final protected function fail(param1:Object) : void
      {
         this.dispatchEvent(new SceneCommandEvent(SceneCommandEvent.FAILED,this,param1));
      }
   }
}

