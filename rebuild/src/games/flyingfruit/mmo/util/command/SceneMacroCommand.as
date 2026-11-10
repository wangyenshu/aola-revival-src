package mmo.util.command
{
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   import flash.utils.getDefinitionByName;
   
   public class SceneMacroCommand implements ISceneCommand, IEventDispatcher
   {
      
      private var _eventDispatcher:EventDispatcher;
      
      private var _subCommands:Array;
      
      private var _executeCommands:Array;
      
      private var _content:Object;
      
      private var _semaphore:int;
      
      private var _executingList:Array;
      
      public function SceneMacroCommand()
      {
         super();
         this._eventDispatcher = new EventDispatcher();
         this._semaphore = 0;
         this._subCommands = [];
         this.initializeMacroCommand();
      }
      
      final public function execute(param1:Object) : void
      {
         if(this._semaphore > 0)
         {
            return;
         }
         this._executeCommands = this._subCommands.concat();
         this.executeNextCommand(param1);
      }
      
      final public function cancel() : void
      {
         var _loc1_:ISceneCommand = null;
         for each(_loc1_ in this._executingList)
         {
            _loc1_.cancel();
         }
         this._semaphore = 0;
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
      
      protected function initializeMacroCommand() : void
      {
      }
      
      protected function addSubCommand(param1:*) : void
      {
         this.addParallelSubCommand([param1]);
      }
      
      protected function addParallelSubCommand(param1:Array) : void
      {
         this._subCommands.push(param1);
      }
      
      private function executeNextCommand(param1:Object) : void
      {
         var _loc2_:Array = null;
         var _loc3_:String = null;
         var _loc4_:* = undefined;
         var _loc5_:ISceneCommand = null;
         if(this._executeCommands.length > 0)
         {
            _loc2_ = this._executeCommands.shift();
            this._executingList = [];
            this._semaphore = _loc2_.length;
            this._content = {};
            for(_loc3_ in param1)
            {
               this._content[_loc3_] = param1[_loc3_];
            }
            for each(_loc4_ in _loc2_)
            {
               _loc5_ = this.getCommandInstance(_loc4_);
               this._executingList.push(_loc5_);
               _loc5_.addEventListener(SceneCommandEvent.SUCCEED,this.onCommandSucc);
               _loc5_.addEventListener(SceneCommandEvent.FAILED,this.onCommandFail);
               _loc5_.execute(param1);
            }
         }
         else
         {
            this._semaphore = 0;
            this.succeed(param1);
         }
      }
      
      private function getCommandInstance(param1:*) : ISceneCommand
      {
         var _loc2_:Class = null;
         if(param1 is Class)
         {
            return new param1();
         }
         if(typeof param1 == "string")
         {
            _loc2_ = getDefinitionByName(param1) as Class;
            return new _loc2_();
         }
         return param1;
      }
      
      private function onCommandSucc(param1:SceneCommandEvent) : void
      {
         var _loc4_:String = null;
         var _loc2_:ISceneCommand = param1.command;
         var _loc3_:int = this._executingList.indexOf(_loc2_);
         this._executingList.splice(_loc3_,1);
         _loc2_.removeEventListener(SceneCommandEvent.FAILED,this.onCommandFail);
         _loc2_.removeEventListener(SceneCommandEvent.SUCCEED,this.onCommandSucc);
         for(_loc4_ in param1.params)
         {
            this._content[_loc4_] = param1.params[_loc4_];
         }
         this.checkSemaphore();
      }
      
      private function onCommandFail(param1:SceneCommandEvent) : void
      {
         var _loc4_:String = null;
         var _loc5_:ISceneCommand = null;
         var _loc2_:ISceneCommand = param1.command;
         var _loc3_:int = this._executingList.indexOf(_loc2_);
         this._executingList.splice(_loc3_,1);
         _loc2_.removeEventListener(SceneCommandEvent.FAILED,this.onCommandFail);
         _loc2_.removeEventListener(SceneCommandEvent.SUCCEED,this.onCommandSucc);
         for(_loc4_ in param1.params)
         {
            this._content[_loc4_] = param1.params[_loc4_];
         }
         for each(_loc5_ in this._executingList)
         {
            _loc5_.cancel();
         }
         this.fail(this._content);
      }
      
      private function checkSemaphore() : void
      {
         --this._semaphore;
         if(this._semaphore == 0)
         {
            this.executeNextCommand(this._content);
         }
      }
      
      private function succeed(param1:Object) : void
      {
         this._semaphore = 0;
         this.dispatchEvent(new SceneCommandEvent(SceneCommandEvent.SUCCEED,this,param1));
      }
      
      private function fail(param1:Object) : void
      {
         this._semaphore = 0;
         this.dispatchEvent(new SceneCommandEvent(SceneCommandEvent.FAILED,this,param1));
      }
   }
}

