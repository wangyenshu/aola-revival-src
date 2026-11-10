package mmo.game.flyingfruit.fruit
{
   public interface IFFStrategy
   {
      
      function startFly(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void;
      
      function beHitted(param1:Boolean, param2:int) : void;
      
      function bomb() : void;
      
      function dispose() : void;
   }
}

