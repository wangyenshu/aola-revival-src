package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   
   public class Fruit5 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit5()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 5;
         this.score = 50;
         this.state = "normal";
         this.isDropping = true;
         this.droppingId = 8;
         this.strategy = new FFNormalStragety(this);
      }
   }
}

