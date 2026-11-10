package mmo.common
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   
   public class BitmapMovieClip extends Bitmap
   {
      
      private var _curFrame:int = 1;
      
      private var _frames:Vector.<Object>;
      
      private var _canvasRectangle:Rectangle;
      
      private var _offsetX:int;
      
      private var _offsetY:int;
      
      private var _isPlaying:Boolean = false;
      
      private var _labels:Array;
      
      private var _frameScripts:Array;
      
      private var _mc:MovieClip;
      
      private var _mcContainer:Sprite;
      
      private var _curCacheFrameIndex:int;
      
      private var _totalFrames:int;
      
      private var _cacheFrames:int;
      
      public function BitmapMovieClip(param1:MovieClip, param2:String = "auto", param3:Boolean = false)
      {
         super();
         if(param1 == null)
         {
            throw new ArgumentError("参数不能为空");
         }
         this._totalFrames = param1.totalFrames;
         this._mc = param1;
         this._mcContainer = new Sprite();
         this._mcContainer.addChild(param1);
         param1.x = 0;
         param1.y = 0;
         this._frameScripts = [];
         this.pixelSnapping = param2;
         this.smoothing = param3;
         var _loc4_:Object = this.getMaxFrameAndMaxRect(param1);
         this._cacheFrames = _loc4_.frame;
         this.setCanvasRect(_loc4_.rect);
         param1.x -= this._offsetX;
         param1.y -= this._offsetY;
         this._frames = new Vector.<Object>();
         this._labels = [];
         this._curCacheFrameIndex = 0;
         this.cacheFrameBitmapDatas(param1);
         ++this._curCacheFrameIndex;
         this.addEventListener(Event.ENTER_FRAME,this.cache,false,int.MAX_VALUE);
         this.refreshFrame();
         this.play();
         this.x = 0;
         this.y = 0;
      }
      
      override public function set x(param1:Number) : void
      {
         super.x = param1 + this._offsetX;
      }
      
      override public function set y(param1:Number) : void
      {
         super.y = param1 + this._offsetY;
      }
      
      override public function get x() : Number
      {
         return super.x - this._offsetX;
      }
      
      override public function get y() : Number
      {
         return super.y - this._offsetY;
      }
      
      public function get currentFrame() : int
      {
         return this._curFrame;
      }
      
      public function get currentFrameLabel() : String
      {
         var _loc1_:Object = this._frames[this._curFrame - 1].frameLabel;
         return _loc1_.name;
      }
      
      public function get currentLabels() : Array
      {
         return this._labels;
      }
      
      public function get totalFrames() : int
      {
         return this._totalFrames;
      }
      
      public function get isPlaying() : Boolean
      {
         return this._isPlaying;
      }
      
      public function clone(param1:Number = 0, param2:Number = 0) : Bitmap
      {
         var _loc3_:Bitmap = new Bitmap(this.bitmapData,this.pixelSnapping,this.smoothing);
         _loc3_.x = this._offsetX + param1;
         _loc3_.y = this._offsetY + param2;
         return _loc3_;
      }
      
      public function gotoAndPlay(param1:Object) : void
      {
         var _loc2_:Object = null;
         if(param1 is String)
         {
            for each(_loc2_ in this._labels)
            {
               if(_loc2_.name == String(param1))
               {
                  this.gotoAndStop(_loc2_.frame);
                  this.play();
                  return;
               }
            }
         }
         else if(param1 is int)
         {
            this.gotoAndStop(param1);
            this.play();
         }
      }
      
      public function gotoAndStop(param1:Object) : void
      {
         var _loc2_:Object = null;
         if(param1 is String)
         {
            for each(_loc2_ in this._labels)
            {
               if(_loc2_.name == String(param1))
               {
                  this._curFrame = _loc2_.frame;
                  this.refreshFrame();
                  this.stop();
                  return;
               }
            }
         }
         else if(param1 is int)
         {
            this._curFrame = int(param1);
            this.refreshFrame();
            this.stop();
         }
      }
      
      public function nextFrame() : void
      {
         if(this._curFrame >= this.totalFrames)
         {
            return;
         }
         ++this._curFrame;
         this.refreshFrame();
      }
      
      public function prevFrame() : void
      {
         if(this._curFrame <= 1)
         {
            return;
         }
         --this._curFrame;
         this.refreshFrame();
      }
      
      public function play() : void
      {
         this.addEventListener(Event.ENTER_FRAME,this.onFrame);
         this._isPlaying = true;
      }
      
      public function stop() : void
      {
         this.removeEventListener(Event.ENTER_FRAME,this.onFrame);
         this._isPlaying = false;
      }
      
      public function addFrameScript(... rest) : void
      {
         var _loc4_:int = 0;
         var _loc5_:Function = null;
         if(rest == null || rest.length == 0 || rest.length % 2 == 1)
         {
            return;
         }
         var _loc2_:int = rest.length / 2;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_)
         {
            _loc4_ = int(rest[_loc3_ * 2]);
            if(!(_loc4_ >= this.totalFrames || _loc4_ < 0))
            {
               _loc5_ = rest[_loc3_ * 2 + 1];
               if(_loc5_ != null)
               {
                  this._frameScripts[_loc4_] = _loc5_;
               }
            }
            _loc3_++;
         }
      }
      
      public function dispose() : void
      {
         this.stop();
         this.bitmapData.dispose();
         this.removeEventListener(Event.ENTER_FRAME,this.cache);
         this._frameScripts = null;
         this._labels = null;
         this._frames = null;
      }
      
      private function setCanvasRect(param1:Rectangle) : void
      {
         var _loc6_:Rectangle = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         _loc2_ = param1.left;
         _loc3_ = param1.right;
         _loc4_ = param1.top;
         _loc5_ = param1.bottom;
         this._offsetX = _loc2_;
         this._offsetY = _loc4_;
         var _loc7_:int = _loc3_ - _loc2_;
         var _loc8_:int = _loc5_ - _loc4_;
         this._canvasRectangle = new Rectangle(0,0,_loc7_,_loc8_);
         this.bitmapData = new BitmapData(this._canvasRectangle.width,this._canvasRectangle.height,true,0);
      }
      
      private function cacheFrameBitmapDatas(param1:MovieClip) : void
      {
         var _loc2_:BitmapData = null;
         var _loc3_:String = null;
         var _loc4_:Object = null;
         param1.gotoAndStop(this._curCacheFrameIndex + 1);
         _loc3_ = param1.currentFrameLabel;
         _loc4_ = {
            "frame":this._curCacheFrameIndex + 1,
            "name":_loc3_
         };
         if(_loc3_ != null && _loc3_ != "")
         {
            this._labels.push(_loc4_);
         }
         if(this._frames != null && (param1.width == 0 || param1.height == 0))
         {
            this._frames.push({
               "data":null,
               "frameLabel":_loc4_
            });
            return;
         }
         _loc2_ = new BitmapData(this._canvasRectangle.width,this._canvasRectangle.height,true,0);
         _loc2_.draw(this._mcContainer);
         if(this._frames != null)
         {
            this._frames.push({
               "data":_loc2_,
               "frameLabel":_loc4_
            });
         }
      }
      
      private function cache(param1:Event) : void
      {
         this._mc.x = -this._offsetX;
         this._mc.y = -this._offsetY;
         this.cacheFrameBitmapDatas(this._mc);
         ++this._curCacheFrameIndex;
         if(this._curCacheFrameIndex >= this._cacheFrames)
         {
            this.removeEventListener(Event.ENTER_FRAME,this.cache);
            this._mc = null;
            this._mcContainer = null;
         }
      }
      
      private function onFrame(param1:Event) : void
      {
         this.refreshFrame();
         if(this._frames != null && ++this._curFrame > this._frames.length)
         {
            this._curFrame = 1;
         }
      }
      
      private function refreshFrame() : void
      {
         this.bitmapData.fillRect(this._canvasRectangle,0);
         var _loc1_:BitmapData = this._frames[this._curFrame - 1].data as BitmapData;
         if(_loc1_ == null)
         {
            this.applyFrameScript();
            return;
         }
         this.bitmapData.copyPixels(_loc1_,this._canvasRectangle,new Point(0,0));
         this.applyFrameScript();
      }
      
      private function applyFrameScript() : void
      {
         if(this._frameScripts.length <= 0)
         {
            return;
         }
         var _loc1_:Function = this._frameScripts[this._curFrame - 1];
         if(_loc1_ != null)
         {
            _loc1_.apply();
         }
      }
      
      private function getMaxFrameAndMaxRect(param1:MovieClip) : Object
      {
         var _loc8_:Rectangle = null;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc13_:DisplayObject = null;
         var _loc14_:Object = null;
         var _loc15_:Rectangle = null;
         var _loc16_:int = 0;
         var _loc2_:Object = {};
         var _loc3_:int = param1.totalFrames;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc9_:int = param1.totalFrames;
         var _loc10_:int = 1;
         while(_loc10_ <= _loc9_)
         {
            param1.gotoAndStop(_loc10_);
            _loc8_ = param1.getBounds(this._mcContainer);
            if(!(_loc8_.width == 0 || _loc8_.height == 0))
            {
               if(_loc10_ == 1)
               {
                  _loc4_ = _loc8_.left;
                  _loc5_ = _loc8_.right;
                  _loc6_ = _loc8_.top;
                  _loc7_ = _loc8_.bottom;
               }
               else
               {
                  _loc4_ = _loc8_.left < _loc4_ ? int(_loc8_.left) : _loc4_;
                  _loc5_ = _loc8_.right > _loc5_ ? int(_loc8_.right) : _loc5_;
                  _loc6_ = _loc8_.top < _loc6_ ? int(_loc8_.top) : _loc6_;
                  _loc7_ = _loc8_.bottom > _loc7_ ? int(_loc8_.bottom) : _loc7_;
               }
               _loc11_ = param1.numChildren;
               _loc12_ = 0;
               while(_loc12_ < _loc11_)
               {
                  _loc13_ = param1.getChildAt(_loc12_);
                  if(_loc13_ is MovieClip)
                  {
                     _loc14_ = this.getMaxFrameAndMaxRect(_loc13_ as MovieClip);
                     _loc15_ = _loc14_.rect;
                     _loc4_ = _loc4_ < _loc15_.left ? _loc4_ : int(_loc15_.left);
                     _loc5_ = _loc5_ > _loc15_.right ? _loc5_ : int(_loc15_.right);
                     _loc6_ = _loc6_ < _loc15_.top ? _loc6_ : int(_loc15_.top);
                     _loc7_ = _loc7_ > _loc15_.bottom ? _loc7_ : int(_loc15_.bottom);
                     _loc16_ = int(_loc14_.frame);
                     _loc3_ = _loc3_ < _loc16_ ? _loc16_ : _loc3_;
                  }
                  _loc12_++;
               }
               param1.gotoAndPlay(1);
            }
            _loc10_++;
         }
         _loc2_.rect = new Rectangle(_loc4_,_loc6_,_loc5_ - _loc4_,_loc7_ - _loc6_);
         _loc2_.frame = _loc3_;
         return _loc2_;
      }
   }
}

