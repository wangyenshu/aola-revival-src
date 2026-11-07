package mmo.thinktower.interact
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class ThunderSendInteract implements Iinteract
   {
      
      private var params:Array;
      
      private var fun:Function;
      
      public function ThunderSendInteract()
      {
         super();
      }
      
      public function dispose() : void
      {
         MovieClip(this.params[0]).removeEventListener(Event.ENTER_FRAME,this.onEnterframe);
         this.params = null;
      }
      
      public function initInterrace(param1:Array, param2:Function) : void
      {
         this.params = param1;
         this.fun = param2;
         MovieClip(param1[0]).addEventListener(Event.ENTER_FRAME,this.onEnterframe);
      }
      
      private function onEnterframe(param1:Event) : void
      {
         var _loc2_:PlayerBase = PlayerManager.getInstance().myPlayer;
         if(MovieClip(this.params[0]).hitTestPoint(_loc2_.x,_loc2_.y))
         {
            _loc2_.jumpTo(Point(this.params[1]).x,Point(this.params[1]).y);
            if(this.fun != null)
            {
               this.fun.apply();
            }
         }
      }
   }
}

