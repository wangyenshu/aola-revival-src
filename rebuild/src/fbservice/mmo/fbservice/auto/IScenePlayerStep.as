package mmo.fbservice.auto
{
   public interface IScenePlayerStep
   {
      
      function init(param1:String, param2:Boolean, param3:Function = null, param4:Object = null) : void;
      
      function dispose() : void;
   }
}

