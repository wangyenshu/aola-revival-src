package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   
   public class Fruit3 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit3()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 3;
         this.score = 150;
         this.state = "normal";
         this.strategy = new FFNormalStragety(this);
      }
   }
}

