package mmo.game.flyingfruit.fruit.strategy
{
   import flash.display.MovieClip;
   import mmo.game.flyingfruit.FFInstanceManager;
   import mmo.game.flyingfruit.FlyingFruitManager;
   import mmo.game.flyingfruit.fruit.FruitBase;
   import mmo.game.flyingfruit.fruit.IFFStrategy;
   import mmo.game.flyingfruit.fruit.MoveDateConfig;
   import mmo.game.flyingfruit.sound.SongController;
   
   public class FFClockStragety implements IFFStrategy
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
      
      public function FFClockStragety(param1:FruitBase)
      {
         super();
         this.disk = param1;
      }
      
      public function startFly(param1:Number = 0, param2:Number = 0, param3:Number = 0, param4:Number = 0) : void
      {
         this.yHeight = param1;
         this.xEndPos = param2;
         this.initXSpeed = param4;
         this.initYSpeed = param3;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.doFly);
      }
      
      private function doFly() : void
      {
         this.disk.x += this.initXSpeed;
         this.disk.y -= this.initYSpeed;
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
         if(!param1)
         {
            SongController.getInstance().playHitClockSound();
         }
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
         FFInstanceManager.instance().adderManager.setAddTimeState(1);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         this.disk.rotation = 0;
         this.disk.state = "doubleScoreHit";
         this.disk.gotoAndStop("doubleScoreHit");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         this.curIcon = _loc1_;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayBomb);
      }
      
      private function normalHitted() : void
      {
         FlyingFruitManager.instance.refreshScore(this.disk.score);
         FFInstanceManager.instance().adderManager.setAddTimeState(1);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         this.disk.rotation = 0;
         this.disk.state = "behitted";
         this.disk.gotoAndStop("behitted");
         var _loc1_:MovieClip = this.disk.getChildByName("icon") as MovieClip;
         _loc1_.addFrameScript(_loc1_.totalFrames - 1,this.onBombEnd);
         this.curIcon = _loc1_;
         FFInstanceManager.instance().enterFrameManager.registerFun(this.onPlayBomb);
      }
      
      private function onPlayBomb() : void
      {
         this.disk.rotation = 0;
         this.curIcon.gotoAndStop(this.curIcon.currentFrame + 1);
      }
      
      private function onBombEnd() : void
      {
         var icon:MovieClip;
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayBomb);
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
         FFInstanceManager.instance().diskManager.removeDisk(this.disk);
      }
      
      public function dispose() : void
      {
         FFInstanceManager.instance().enterFrameManager.removeFun(this.doFly);
         FFInstanceManager.instance().enterFrameManager.removeFun(this.onPlayBomb);
      }
   }
}

