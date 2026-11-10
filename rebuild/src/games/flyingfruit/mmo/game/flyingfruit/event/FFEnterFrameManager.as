package mmo.game.flyingfruit.event
{
   import flash.display.Sprite;
   import flash.events.Event;
   
   public class FFEnterFrameManager extends Sprite
   {
      
      private var funArr:Array;
      
      private var intervalArr:Array;
      
      public var isPause:Boolean = false;
      
      public function FFEnterFrameManager()
      {
         super();
         this.funArr = [];
         this.intervalArr = [];
         this.addEventListener(Event.ENTER_FRAME,this.onFrame);
      }
      
      public function registerFun(param1:Function, param2:int = 1, param3:Array = null) : Boolean
      {
         if(this.getFuncIndex(param1) >= 0)
         {
            return false;
         }
         var _loc4_:EnterFrameParams = new EnterFrameParams(param1,param2,param3);
         this.funArr.push(_loc4_);
         this.intervalArr.push(0);
         return true;
      }
      
      public function removeFun(param1:Function) : Boolean
      {
         var _loc2_:int = this.getFuncIndex(param1);
         if(_loc2_ < 0)
         {
            return false;
         }
         this.funArr.splice(_loc2_,1);
         this.intervalArr.splice(_loc2_,1);
         return true;
      }
      
      private function getFuncIndex(param1:Function) : int
      {
         var _loc2_:int = 0;
         while(_loc2_ < this.funArr.length)
         {
            if(param1 === EnterFrameParams(this.funArr[_loc2_]).fun)
            {
               return _loc2_;
            }
            _loc2_++;
         }
         return -1;
      }
      
      private function onFrame(param1:Event) : void
      {
         var _loc5_:EnterFrameParams = null;
         if(this.isPause)
         {
            return;
         }
         var _loc2_:Array = [];
         var _loc3_:* = int(this.funArr.length - 1);
         while(_loc3_ >= 0)
         {
            _loc5_ = this.funArr[_loc3_];
            ++this.intervalArr[_loc3_];
            if(this.intervalArr[_loc3_] == _loc5_.interval)
            {
               _loc2_.push(_loc5_);
            }
            _loc3_--;
         }
         var _loc4_:* = int(_loc2_.length - 1);
         while(_loc4_ >= 0)
         {
            this.intervalArr[this.getFuncIndex(EnterFrameParams(_loc2_[_loc4_]).fun)] = 0;
            EnterFrameParams(_loc2_[_loc4_]).fun.apply(null,EnterFrameParams(_loc2_[_loc4_]).params);
            _loc4_--;
         }
      }
      
      public function pause() : void
      {
         this.isPause = true;
      }
      
      public function play() : void
      {
         this.isPause = false;
      }
      
      public function dispose() : void
      {
         this.funArr = [];
         this.intervalArr = [];
         this.removeEventListener(Event.ENTER_FRAME,this.onFrame);
      }
   }
}

