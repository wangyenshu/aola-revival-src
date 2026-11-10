package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   
   public class Fruit2 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit2()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 2;
         this.score = 100;
         this.state = "normal";
         this.strategy = new FFNormalStragety(this);
      }
   }
}

