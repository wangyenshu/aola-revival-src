package mmo.game.flyingfruit.fruit.strategy
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.FFInstanceManager;
   import mmo.game.flyingfruit.FlyingFruitManager;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.IFFStrategy;
   import mmo.game.flyingfruit.fruit.MoveDateConfig;
   import mmo.game.flyingfruit.sound.SongController;
   
   public class FFBombStragety implements IFFStrategy
   {
      
      private var disk:FruitBase;
      
      private var yHeight:Number;
      
      private var xEndPos:Number;
      
      private var initYSpeed:Number;
      
      private var initXSpeed:Number;
      
      private var angelDivisor:int;
      
      private var isBombByBomb:Boolean = false;
      
      private var curIcon:MovieClip;
      
      private var curMultiNum:int = 0;
      
      public function FFBombStragety(param1:FruitBase)
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
         this.isBombByBomb = param1;
         this.curMultiNum = param2;
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         if(FFInstanceManager.instance().adderManager.isDoubleScore)
         {
            this.doubleScoreHitted();
            SongController.getInstance().playHitBombSound();
         }
         else
         {
            if(this.isBombByBomb)
            {
               this.onBombEnd();
               return;
            }
            SongController.getInstance().playHitBombSound();
            FFInstanceManager.instance().mainPanel.showBombPanel();
            FFInstanceManager.instance().mainPanel.resetAnger();
            this.normalHitted();
         }
      }
      
      private function doubleScoreHitted() : void
      {
         FlyingFruitManager.instance.refreshScore(-this.disk.score * 2);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         this.disk.rotation = 0;
         this.disk.state = "doubleScoreHit";
         this.disk.gotoAndStop("doubleScoreHit");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         this.curIcon = _loc1_;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayDoubleBomb);
      }
      
      private function onPlayDoubleBomb() : void
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
      
      private function normalHitted() : void
      {
         FFInstanceManager.instance().diskManager.allDiskesBombNoScore(this.disk);
         FlyingFruitManager.instance.refreshScore(this.disk.score);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         this.disk.rotation = 0;
         this.disk.state = "behitted";
         this.disk.gotoAndStop("behitted");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         _loc1_.gotoAndPlay(1);
      }
      
      private function onBombEnd() : void
      {
         var icon:MovieClip;
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayDoubleBomb);
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
         FFInstanceManager.instance().diskManager.removeDisk(this.disk);
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayDoubleBomb);
      }
   }
}

