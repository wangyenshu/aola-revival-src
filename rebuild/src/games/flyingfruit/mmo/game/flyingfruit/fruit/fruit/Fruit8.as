package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFToolStragety;
   
   public class Fruit8 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit8()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 8;
         var _loc1_:Number = Math.random();
         var _loc2_:MovieClip = this.getChildByName("icon") as MovieClip;
         if(_loc1_ < 0.5)
         {
            this.score = 1000;
            _loc2_.gotoAndStop(1);
            this.subId = 1;
         }
         else
         {
            this.score = 2000;
            _loc2_.gotoAndStop(2);
            this.subId = 2;
         }
         this.state = "normal";
         this.strategy = new FFToolStragety(this);
      }
      
      override public function reSetDiskState() : void
      {
         this.gotoAndStop("normal");
         this.state = "normal";
         var _loc1_:Number = Math.random();
         var _loc2_:MovieClip = this.getChildByName("icon") as MovieClip;
         if(_loc1_ < 0.5)
         {
            this.score = 1000;
            _loc2_.gotoAndStop(1);
            this.subId = 1;
         }
         else
         {
            this.score = 2000;
            _loc2_.gotoAndStop(2);
            this.subId = 2;
         }
         this.removeListeners();
      }
   }
}

