package mmo.fbteam.auto
{
   public interface IScenePlayerStep
   {
      
      function run(param1:String, param2:Function = null, param3:Object = null) : void;
      
      function dispose() : void;
   }
}

