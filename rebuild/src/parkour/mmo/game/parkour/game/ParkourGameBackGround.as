package mmo.game.parkour.game
{
   import flash.display.MovieClip;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   
   public class ParkourGameBackGround extends MovieClip
   {
      
      private var field:int;
      
      public function ParkourGameBackGround(param1:int)
      {
         super();
         this.field = param1;
      }
      
      public function loadView() : void
      {
         var _loc1_:MovieClip = ParkourGameResConfig.createDisplayObj(ParkourGameResConfig.PreClsNameOfBackGround + this.field) as MovieClip;
         addChild(_loc1_);
      }
   }
}

