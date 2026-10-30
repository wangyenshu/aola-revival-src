package mmo.shoot
{
   import flash.display.MovieClip;
   
   public class TargetIcon extends MovieClip
   {
      
      private static var _instance:TargetIcon;
      
      public function TargetIcon()
      {
         addFrameScript(0,this.frame1,1,this.frame2);
         this.stop();
         this.mouseEnabled = false;
         super();
      }
      
      public static function get instance() : TargetIcon
      {
         if(_instance == null)
         {
            _instance = new TargetIcon();
         }
         return _instance;
      }
      
      override public function gotoAndPlay(param1:Object, param2:String = null) : void
      {
         if(this.currentFrame == param1)
         {
            return;
         }
         super.gotoAndPlay(param1,param2);
      }
      
      override public function gotoAndStop(param1:Object, param2:String = null) : void
      {
         if(this.currentFrame == param1)
         {
            return;
         }
         super.gotoAndStop(param1,param2);
      }
      
      public function showNormal() : void
      {
         this.gotoAndStop(1);
      }
      
      public function showActive() : void
      {
         this.gotoAndStop(2);
      }
      
      internal function frame1() : *
      {
         this.stop();
      }
      
      internal function frame2() : *
      {
         this.stop();
      }
   }
}

