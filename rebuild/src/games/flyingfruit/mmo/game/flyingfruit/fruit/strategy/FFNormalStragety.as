package mmo.game.flyingfruit.fruit.strategy
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.FFInstanceManager;
   import mmo.game.flyingfruit.FlyingFruitManager;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.IFFStrategy;
   import mmo.game.flyingfruit.fruit.MoveDateConfig;
   import mmo.game.flyingfruit.sound.SongController;
   
   public class FFNormalStragety implements IFFStrategy
   {
      
      private var disk:FruitBase;
      
      private var yHeight:Number;
      
      private var xEndPos:Number;
      
      private var initYSpeed:Number;
      
      private var initXSpeed:Number;
      
      private var angelDivisor:int;
      
      private var newDiskX:Number;
      
      private var newDiskY:Number;
      
      private var isBombByBomb:Boolean = false;
      
      private var curIcon:MovieClip;
      
      private var curMultiNum:int = 0;
      
      public function FFNormalStragety(param1:FruitBase)
      {
         super();
         this.disk = param1;
      }
      
      public function startFly(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void
      {
         var _loc5_:Number = MoveDateConfig.GUN_BOUND_LENGTH;
         var _loc6_:Number = FFInstanceManager.instance().mainPanel.gunXPos;
         var _loc7_:Number = Math.random();
         if(_loc7_ <= 0.33)
         {
            param2 = this.disk.x - Math.random() * (this.disk.x - _loc6_ - _loc5_);
            this.angelDivisor = 6;
         }
         else if(_loc7_ <= 0.66)
         {
            param2 = _loc6_ + (_loc5_ - Math.random() * _loc5_ * 2);
            this.angelDivisor = 4;
         }
         else
         {
            param2 = 960 - this.disk.x;
            this.angelDivisor = 2;
         }
         this.yHeight = Math.random() * MoveDateConfig.Y_LENGTH_AREA;
         var _loc8_:Number = Math.sqrt(2 * (560 - this.yHeight) / MoveDateConfig.GRAVITY);
         this.initXSpeed = (param2 - this.disk.x) / _loc8_ / 2;
         this.initYSpeed = _loc8_ * MoveDateConfig.GRAVITY;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.doFly);
      }
      
      private function doFly() : void
      {
         this.disk.x += this.initXSpeed;
         this.disk.y -= this.initYSpeed;
         this.disk.rotation = -Math.atan(this.initYSpeed / this.initXSpeed) * 180 / Math.PI / this.angelDivisor;
         this.initYSpeed -= MoveDateConfig.GRAVITY;
         if(this.disk.y >= 600)
         {
            this.dispose();
            FFInstanceManager.instance().diskManager.removeDisk(this.disk);
         }
      }
      
      public function beHitted(param1:Boolean, param2:int) : void
      {
         if(this.disk.state != "normal")
         {
            return;
         }
         if(!param1 && this.disk.id < 3)
         {
            SongController.getInstance().playHitDiskSound();
         }
         else if(!param1)
         {
            SongController.getInstance().playHitFlyingDiskSound();
         }
         this.curMultiNum = param2;
         this.isBombByBomb = param1;
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         if(FFInstanceManager.instance().adderManager.isDoubleScore)
         {
            this.doubleScoreHitted();
         }
         else
         {
            this.normalHitted();
         }
      }
      
      private function doubleScoreHitted() : void
      {
         FlyingFruitManager.instance.refreshScore(this.disk.score * 2);
         this.disk.rotation = 0;
         this.disk.state = "doubleScoreHit";
         this.disk.gotoAndStop("doubleScoreHit");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         _loc1_.addFrameScript(5,this.onBombMiddle);
         this.curIcon = _loc1_;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayHittedMovie);
      }
      
      private function normalHitted() : void
      {
         FlyingFruitManager.instance.refreshScore(this.disk.score * this.curMultiNum);
         this.disk.rotation = 0;
         this.disk.state = "behitted";
         this.disk.gotoAndStop("behitted");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         _loc1_.addFrameScript(5,this.onBombMiddle);
         this.curIcon = _loc1_;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayHittedMovie);
      }
      
      private function onPlayHittedMovie() : void
      {
         this.disk.rotation = 0;
         var _loc1_:MovieClip = this.curIcon.getChildByName("icon") as MovieClip;
         if(_loc1_ == null)
         {
            return;
         }
         if(this.curMultiNum > 1)
         {
            _loc1_.gotoAndStop(this.curMultiNum);
         }
         else
         {
            _loc1_.visible = false;
         }
         this.curIcon.gotoAndStop(this.curIcon.currentFrame + 1);
      }
      
      private function onBombMiddle() : void
      {
         var icon:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         icon.addFrameScript(5,function():void
         {
         });
         this.newDiskY = this.disk.y;
         this.newDiskX = this.disk.x;
         if(this.disk.isDropping && !this.isBombByBomb)
         {
            this.addOtherDisk();
         }
      }
      
      private function onBombEnd() : void
      {
         var icon:MovieClip;
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayHittedMovie);
         icon = this.disk.getChildByName("icon") as MovieClip;
         icon.addFrameScript(icon.totalFrames - 1,function():void
         {
         });
         icon.gotoAndStop(1);
         FFInstanceManager.instance().diskManager.removeDisk(this.disk);
      }
      
      public function bomb() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         this.disk.rotation = 0;
         this.disk.state = "bomb";
         this.disk.gotoAndStop("bomb");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         _loc1_.gotoAndPlay(1);
      }
      
      private function addOtherDisk() : void
      {
         var _loc1_:FruitBase = FFInstanceManager.instance().diskManager.getDiskById(this.disk.droppingId);
         _loc1_.x = this.newDiskX;
         _loc1_.y = this.newDiskY;
         FFInstanceManager.instance().mainPanel.addChild(_loc1_);
         _loc1_.startFly(this.yHeight,this.xEndPos,this.initYSpeed,this.initXSpeed);
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayHittedMovie);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
      }
   }
}

