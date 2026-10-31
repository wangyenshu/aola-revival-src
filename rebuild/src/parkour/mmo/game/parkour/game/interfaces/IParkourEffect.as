package mmo.game.parkour.game.interfaces
{
   public interface IParkourEffect
   {
      
      function excute(param1:Object) : Boolean;
      
      function reset(param1:Object) : void;
      
      function run() : void;
      
      function canDispose() : Boolean;
      
      function dispose() : void;
   }
}

