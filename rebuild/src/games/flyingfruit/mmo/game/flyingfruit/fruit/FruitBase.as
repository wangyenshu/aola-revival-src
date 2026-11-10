package mmo.game.flyingfruit.fruit
{
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   
   public class FruitBase extends MovieClip
   {
      
      public var id:int;
      
      public var subId:int = 1;
      
      public var score:int;
      
      public var strategy:IFFStrategy;
      
      public var state:String;
      
      public var isDropping:Boolean = false;
      
      public var droppingId:int = 0;
      
      public function FruitBase()
      {
         super();
      }
      
      public function reSetDiskState() : void
      {
         this.gotoAndStop("normal");
         this.state = "normal";
         this.removeListeners();
      }
      
      public function startFly(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void
      {
         this.strategy.startFly(param1,param2,param3,param4);
      }
      
      public function beHitted(param1:Boolean = false, param2:int = 1) : void
      {
         this.strategy.beHitted(param1,param2);
      }
      
      public function bomb() : void
      {
         this.strategy.bomb();
      }
      
      public function removeListeners() : void
      {
         this.strategy.dispose();
      }
      
      public function dispose() : void
      {
         this.strategy.dispose();
         DisplayUtil.stopAndRemove(this);
      }
   }
}

