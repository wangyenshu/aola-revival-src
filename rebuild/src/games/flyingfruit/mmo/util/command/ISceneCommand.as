package mmo.util.command
{
   import flash.events.IEventDispatcher;
   
   public interface ISceneCommand extends IEventDispatcher
   {
      
      function execute(param1:Object) : void;
      
      function cancel() : void;
   }
}

