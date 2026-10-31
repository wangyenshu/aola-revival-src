package mmo.game.parkour.movie
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourMovieContainer
   {
      
      private var container:Sprite;
      
      private var fullPowerMovie:MovieClip;
      
      public function ParkourMovieContainer()
      {
         super();
         this.container = new Sprite();
      }
      
      public function getContainer() : Sprite
      {
         return this.container;
      }
      
      public function playStartMovie(param1:Function) : void
      {
         var _loc2_:MovieClip = ParkourGameResConfig.createDisplayObj(ParkourGameResConfig.ClsNameOfStartMovie) as MovieClip;
         this.playMovie(_loc2_,param1,true);
      }
      
      public function playPowerFullMovie() : void
      {
         if(this.fullPowerMovie != null)
         {
            return;
         }
         this.fullPowerMovie = ParkourGameResConfig.createDisplayObj(ParkourGameResConfig.ClsNameOfFullPowerMovie) as MovieClip;
         this.playMovie(this.fullPowerMovie,function():*
         {
            fullPowerMovie = null;
         });
      }
      
      public function onUsePower() : void
      {
         if(this.fullPowerMovie != null)
         {
            this.fullPowerMovie.play();
         }
      }
      
      private function playMovie(param1:MovieClip, param2:Function = null, param3:Boolean = false) : void
      {
         var movie:MovieClip = param1;
         var callback:Function = param2;
         var lock:Boolean = param3;
         if(lock)
         {
            lockScreen();
         }
         movie.addFrameScript(movie.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(movie);
            ParkourHelper.applyFunc(callback);
            if(lock)
            {
               unlockScreen();
            }
         });
         movie.gotoAndPlay(1);
         this.container.addChild(movie);
      }
      
      // aola-revival: the later ProgressFullSprite.lockScreen/unlockScreen (the 2013 one has
      // neither): an empty modal dialog, without the grey background, keeps the mouse off the
      // game while its start movie plays.
      private static var _lockSprite:Sprite;
      
      private static function lockScreen() : void
      {
         if(_lockSprite != null)
         {
            return;
         }
         _lockSprite = new Sprite();
         ModalDialogManager.getInstance().addModalDialog(_lockSprite,AlignType.NONE,0,false);
      }
      
      private static function unlockScreen() : void
      {
         if(_lockSprite == null)
         {
            return;
         }
         ModalDialogManager.getInstance().removeModalDialog(_lockSprite);
         _lockSprite = null;
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this.container);
         this.container = null;
      }
   }
}

