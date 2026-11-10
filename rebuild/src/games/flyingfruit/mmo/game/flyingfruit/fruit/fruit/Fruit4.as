package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFNormalStragety;
   
   public class Fruit4 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public function Fruit4()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 4;
         this.score = 50;
         this.state = "normal";
         this.isDropping = true;
         this.droppingId = 7;
         this.strategy = new FFNormalStragety(this);
      }
   }
}

