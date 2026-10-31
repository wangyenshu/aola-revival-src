package mmo.game.parkour.game.teach
{
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import flash.ui.Keyboard;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.game.parkour.game.ParkourGameScene;
   import mmo.game.parkour.game.config.ParkourGameMapConfig;
   import mmo.game.parkour.game.config.ParkourGameResConfig;
   import mmo.game.parkour.game.player.ParkourPlayer;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.loader.scheduler.ResScheduler;
   
   public class ParkourTeachHelper
   {
      
      private static const TeacherColumns:Array = [10,27,41];
      
      private static const DelayMeters:Array = [1.5 * ParkourGameMapConfig.Interval_Width,1 * ParkourGameMapConfig.Interval_Width,2 * ParkourGameMapConfig.Interval_Width];
      
      private static const NeedKeyCodes:Array = [Keyboard.DOWN,Keyboard.UP,Keyboard.UP];
      
      private var isTeaching:Boolean = false;
      
      private var needTeach:Boolean = true;
      
      private var needKeyCode:uint = 1000000;
      
      private var hadTeachs:Array = [];
      
      private var teachMovie:MovieClip;
      
      public function ParkourTeachHelper(param1:Boolean = true)
      {
         super();
         this.needTeach = param1;
      }
      
      public function isNeedTeach() : Boolean
      {
         return this.needTeach;
      }
      
      public function checkLoadFla(param1:Function = null) : void
      {
         var callback:Function = param1;
         if(!this.needTeach)
         {
            ParkourHelper.applyFunc(callback);
         }
         else
         {
            ProgressFullSprite.show();
            // aola-revival: the 2013 ResScheduler.getResource (into the current domain) for getRes(ResParams…).
            ResScheduler.getResource(ParkourGameResConfig.ResPathOfTeachMovie,function(... rest):void
            {
               ProgressFullSprite.close();
               ParkourHelper.applyFunc(callback);
            });
         }
      }
      
      public function checkTeach(param1:int) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         if(!this.needTeach || this.isTeaching)
         {
            return;
         }
         var _loc2_:int = 0;
         while(_loc2_ < TeacherColumns.length)
         {
            _loc3_ = int(TeacherColumns[_loc2_]);
            _loc4_ = _loc3_ * ParkourGameMapConfig.Interval_Width;
            _loc5_ = int(DelayMeters[_loc2_]);
            if(_loc4_ - (param1 + ParkourPlayer.InitX) <= _loc5_ && this.hadTeachs.indexOf(_loc2_) == -1)
            {
               this.hadTeachs.push(_loc2_);
               this.isTeaching = true;
               this.needKeyCode = NeedKeyCodes[_loc2_];
               ParkourGameScene.instance.pause();
               this.playTeachMovie(_loc2_);
               break;
            }
            _loc2_++;
         }
      }
      
      private function playTeachMovie(param1:int) : void
      {
         var id:int = param1;
         this.teachMovie = ParkourGameResConfig.createDisplayObj(ParkourGameResConfig.PreClsNameOfTeachMovie + id) as MovieClip;
         this.teachMovie.addFrameScript(this.teachMovie.totalFrames - 1,function():void
         {
            isTeaching = false;
            ModalDialogManager.getInstance().removeModalDialog(teachMovie);
            teachMovie = null;
            ParkourGameScene.instance.continueGame();
         });
         this.teachMovie.gotoAndPlay(1);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this.teachMovie,AlignType.NONE);
      }
      
      public function validatePress(param1:uint) : Boolean
      {
         if(!this.needTeach || !this.isTeaching)
         {
            return false;
         }
         if(this.needKeyCode == param1)
         {
            if(this.teachMovie != null)
            {
               this.teachMovie.play();
            }
            return true;
         }
         return false;
      }
      
      public function dispose() : void
      {
         if(this.teachMovie != null)
         {
            ModalDialogManager.getInstance().removeModalDialog(this.teachMovie);
            this.teachMovie = null;
         }
      }
   }
}

