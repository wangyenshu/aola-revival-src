package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   
   public class Fruit1 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit1()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 1;
         this.score = 50;
         this.state = "normal";
         this.strategy = new FFNormalStragety(this);
      }
   }
}

