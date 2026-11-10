package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFClockStragety;
   
   public class Fruit7 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit7()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 7;
         this.score = 0;
         this.state = "normal";
         this.strategy = new FFClockStragety(this);
      }
   }
}

