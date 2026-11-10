package mmo.util.command
{
   import flash.events.Event;
   
   public final class SceneCommandEvent extends Event
   {
      
      public static const SUCCEED:String = "onCommandSucceed";
      
      public static const FAILED:String = "onCommandFailed";
      
      public static const CANCELED:String = "onCommandCanceled";
      
      private var _params:Object;
      
      private var _command:ISceneCommand;
      
      public function SceneCommandEvent(param1:String, param2:ISceneCommand, param3:Object = null)
      {
         super(param1);
         this._command = param2;
         this._params = param3;
      }
      
      public function get params() : Object
      {
         return this._params;
      }
      
      public function get command() : ISceneCommand
      {
         return this._command;
      }
   }
}

