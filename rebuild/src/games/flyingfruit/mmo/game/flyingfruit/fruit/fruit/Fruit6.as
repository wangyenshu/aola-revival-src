package mmo.game.flyingfruit.fruit.fruit
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.strategy.FFBombStragety;
   
   public class Fruit6 extends FruitBase
   {
      
      public var icon:MovieClip;
      
      public var score2:int = 50;
      
      public function Fruit6()
      {
         super();
         this.gotoAndStop("normal");
         this.id = 6;
         this.score = -1000;
         this.state = "normal";
         this.strategy = new FFBombStragety(this);
      }
   }
}

