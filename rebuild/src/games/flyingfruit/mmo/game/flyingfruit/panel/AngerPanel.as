package mmo.game.flyingfruit.panel
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   
   public dynamic class AngerPanel extends MovieClip
   {
      
      public var angerNum:TextField;
      
      public function AngerPanel()
      {
         super();
         addFrameScript(15,this.frame16);
      }
      
      internal function frame16() : *
      {
         stop();
      }
   }
}

