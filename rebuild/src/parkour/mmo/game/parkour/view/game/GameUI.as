package mmo.game.parkour.view.game
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.text.TextField;
   
   public dynamic class GameUI extends MovieClip
   {
      
      public var txtScore:TextField;
      
      public var btnPause:SimpleButton;
      
      public var txtMeter:TextField;
      
      public var mcPower:MovieClip;
      
      public function GameUI()
      {
         super();
      }
   }
}

