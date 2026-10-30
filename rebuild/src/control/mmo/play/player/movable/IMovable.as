package mmo.play.player.movable
{
   import flash.events.IEventDispatcher;
   import mmo.interfaces.IDispose;
   import mmo.play.player.movable.strategy.IMovingStrategy;

   /** REBUILT. Something that walks around a scene (players, scene pets). */
   public interface IMovable extends IEventDispatcher, IDispose
   {
      function get walkSpeed():int;
      function set walkSpeed(v:int):void;
      function get direction():int;
      function get destX():int;
      function get destY():int;
      function get x():Number;
      function set x(v:Number):void;
      function get y():Number;
      function set y(v:Number):void;
      function isMoving():Boolean;
      function walkTo(x:int, y:int):Object;
      function moveTo(x:int, y:int, speed:int = -1):Object;
      function jumpTo(x:int, y:int):Object;
      function stop():Object;
      function setStrategy(strategy:IMovingStrategy):void;
   }
}
