package mmo.common
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.PixelSnapping;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.filters.BitmapFilterQuality;
   import flash.filters.ColorMatrixFilter;
   import flash.filters.GlowFilter;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   
   public class DisplayUtil extends Dictionary
   {
      
      public function DisplayUtil()
      {
         super();
      }
      
      public static function replace(param1:DisplayObject, param2:DisplayObject) : Boolean
      {
         if(param1.parent == null || !param1.parent.contains(param1))
         {
            return false;
         }
         param2.x = param1.x;
         param2.y = param1.y;
         param2.width = param1.width;
         param2.height = param1.height;
         param1.parent.addChildAt(param2,param1.parent.getChildIndex(param1));
         param1.parent.removeChild(param1);
         return true;
      }
      
      public static function replaceAsBitmap(param1:DisplayObject, param2:int = 0) : Bitmap
      {
         var _loc3_:DisplayObjectContainer = param1.parent;
         if(_loc3_ == null || !_loc3_.contains(param1))
         {
            throw new Error("待缓存的元件不在显示列表中");
         }
         var _loc4_:int = _loc3_.getChildIndex(param1);
         var _loc5_:Number = param1.x;
         var _loc6_:Number = param1.y;
         var _loc7_:Bitmap = cacheAsBitmap(param1,param2);
         if(_loc7_ == null)
         {
            return null;
         }
         _loc7_.name = param1.name;
         _loc7_.x += param1.x;
         _loc7_.y += param1.y;
         _loc3_.addChildAt(_loc7_,_loc4_);
         DisplayUtil.stopAndRemove(param1);
         return _loc7_;
      }
      
      public static function cacheAsBitmap(param1:DisplayObject, param2:int = 0) : Bitmap
      {
         var _loc9_:Bitmap = null;
         var _loc10_:Rectangle = null;
         var _loc11_:Matrix = null;
         var _loc12_:BitmapData = null;
         var _loc3_:int = 0;
         var _loc4_:DisplayObjectContainer = null;
         if(param1.parent != null)
         {
            _loc4_ = param1.parent;
            _loc3_ = _loc4_.getChildIndex(param1);
         }
         setEvent(param1,false);
         var _loc5_:Number = param1.x;
         var _loc6_:Number = param1.y;
         param1.x = param1.y = 0;
         var _loc7_:Sprite = new Sprite();
         _loc7_.addChild(param1);
         var _loc8_:Rectangle = param1.getBounds(_loc7_);
         if(_loc8_.width > 0 && _loc8_.height > 0)
         {
            _loc10_ = new Rectangle();
            _loc10_.x = int(_loc8_.x);
            _loc10_.y = int(_loc8_.y);
            _loc10_.width = Number(_loc8_.width + _loc8_.x - Number(_loc10_.x));
            _loc10_.height = Number(_loc8_.height + _loc8_.y - Number(_loc10_.y));
            _loc11_ = new Matrix();
            _loc11_.translate(-_loc10_.x,-_loc10_.y);
            _loc11_.translate(param2,param2);
            _loc12_ = new BitmapData(getMipmapValue(_loc10_.width + 1 + param2 * 2),getMipmapValue(_loc10_.height + 1 + param2 * 2),true,0);
            _loc12_.draw(_loc7_,_loc11_);
            _loc9_ = new Bitmap(_loc12_,PixelSnapping.AUTO,true);
            _loc9_.x = _loc10_.x - param2;
            _loc9_.y = _loc10_.y - param2;
         }
         param1.x = _loc5_;
         param1.y = _loc6_;
         if(_loc4_ != null)
         {
            _loc4_.addChildAt(param1,_loc3_);
         }
         setEvent(param1,true);
         return _loc9_;
      }
      
      public static function cloneAsBitmap(param1:DisplayObject, param2:Boolean = true) : Bitmap
      {
         var _loc6_:Bitmap = null;
         var _loc7_:Rectangle = null;
         var _loc8_:Matrix = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:BitmapData = null;
         if(param1 == null)
         {
            throw new Error("被克隆的元件不能为空。");
         }
         var _loc3_:Number = param1.x;
         var _loc4_:Number = param1.y;
         param1.x = param1.y = 0;
         var _loc5_:Rectangle = param1.getBounds(param1);
         if(_loc5_.width > 0 && _loc5_.height > 0)
         {
            _loc7_ = new Rectangle();
            _loc7_.x = int(_loc5_.x);
            _loc7_.y = int(_loc5_.y);
            _loc7_.width = Number(_loc5_.width + _loc5_.x - Number(_loc7_.x));
            _loc7_.height = Number(_loc5_.height + _loc5_.y - Number(_loc7_.y));
            _loc8_ = new Matrix();
            _loc8_.translate(-_loc7_.x,-_loc7_.y);
            _loc9_ = param2 ? getMipmapValue(_loc7_.width + 1) : int(_loc7_.width);
            _loc10_ = param2 ? getMipmapValue(_loc7_.height + 1) : int(_loc7_.height);
            _loc11_ = new BitmapData(_loc9_,_loc10_,true,0);
            _loc11_.draw(param1,_loc8_);
            _loc6_ = new Bitmap(_loc11_,PixelSnapping.AUTO,false);
            _loc6_.x = _loc5_.x;
            _loc6_.y = _loc5_.y;
         }
         param1.x = _loc3_;
         param1.y = _loc4_;
         return _loc6_;
      }
      
      public static function cloneDisplayObject(param1:DisplayObject) : DisplayObject
      {
         if(param1 == null)
         {
            throw new Error("被克隆的元件不能为空。");
         }
         var _loc2_:Class = Object(param1).constructor;
         var _loc3_:DisplayObject = new _loc2_();
         _loc3_.filters = param1.filters;
         _loc3_.transform = param1.transform;
         _loc3_.cacheAsBitmap = param1.cacheAsBitmap;
         _loc3_.opaqueBackground = param1.opaqueBackground;
         return _loc3_;
      }
      
      public static function getActualBounds(param1:DisplayObject) : Rectangle
      {
         var _loc6_:Sprite = null;
         setEvent(param1,false);
         var _loc2_:Boolean = true;
         if(param1.parent == null)
         {
            _loc2_ = false;
            _loc6_ = new Sprite();
            _loc6_.addChild(param1);
         }
         var _loc3_:Number = param1.x;
         var _loc4_:Number = param1.y;
         param1.x = 0;
         param1.y = 0;
         var _loc5_:Rectangle = param1.getBounds(param1.parent);
         if(!_loc2_)
         {
            param1.parent.removeChild(param1);
         }
         setEvent(param1,true);
         param1.x = _loc3_;
         param1.y = _loc4_;
         return _loc5_;
      }
      
      public static function applyGray(param1:DisplayObject) : void
      {
         var _loc2_:Array = new Array();
         _loc2_ = _loc2_.concat([0.3086,0.6094,0.082,0,0]);
         _loc2_ = _loc2_.concat([0.3086,0.6094,0.082,0,0]);
         _loc2_ = _loc2_.concat([0.3086,0.6094,0.082,0,0]);
         _loc2_ = _loc2_.concat([0,0,0,1,0]);
         applyFilter(param1,_loc2_);
      }
      
      public static function setBrightHalf(param1:DisplayObject) : void
      {
         var _loc2_:Array = new Array();
         _loc2_ = _loc2_.concat([1,0,0,0,-100]);
         _loc2_ = _loc2_.concat([0,1,0,0,-100]);
         _loc2_ = _loc2_.concat([0,0,1,0,-100]);
         _loc2_ = _loc2_.concat([0,0,0,1,0]);
         applyFilter(param1,_loc2_);
      }
      
      public static function clearFilters(param1:DisplayObject) : void
      {
         param1.filters = null;
      }
      
      public static function getColor(param1:DisplayObject, param2:uint = 0, param3:uint = 0, param4:Boolean = false) : uint
      {
         var _loc5_:BitmapData = new BitmapData(param1.width,param1.height);
         _loc5_.draw(param1);
         var _loc6_:uint = !param4 ? _loc5_.getPixel(int(param2),int(param3)) : _loc5_.getPixel32(int(param2),int(param3));
         _loc5_.dispose();
         return _loc6_;
      }
      
      public static function localToLocal(param1:DisplayObject, param2:DisplayObject, param3:Point = null) : Point
      {
         if(param3 == null)
         {
            param3 = new Point(0,0);
         }
         if(param1 == null || param2 == null)
         {
            return null;
         }
         param3 = param1.localToGlobal(param3);
         return param2.globalToLocal(param3);
      }
      
      public static function align(param1:DisplayObject, param2:Rectangle = null, param3:int = 4, param4:Point = null) : void
      {
         if(param3 == AlignType.NONE)
         {
            return;
         }
         if(param2 == null)
         {
            param2 = new Rectangle(0,0,960,560);
         }
         if(param4)
         {
            param2.offsetPoint(param4);
         }
         var _loc5_:* = param1.getRect(param1);
         var _loc6_:* = param2.width - param1.width;
         var _loc7_:* = param2.height - param1.height;
         switch(param3)
         {
            case AlignType.TOP_LEFT:
               param1.x = param2.x;
               param1.y = param2.y;
               break;
            case AlignType.TOP_CENTER:
               param1.x = param2.x + (_loc6_ >> 1) - _loc5_.x;
               param1.y = param2.y;
               break;
            case AlignType.TOP_RIGHT:
               param1.x = param2.x + _loc6_ - _loc5_.x;
               param1.y = param2.y;
               break;
            case AlignType.MIDDLE_LEFT:
               param1.x = param2.x;
               param1.y = param2.y + (_loc7_ >> 1) - _loc5_.x;
               break;
            case AlignType.MIDDLE_CENTER:
               param1.x = param2.x + (_loc6_ >> 1) - _loc5_.x;
               param1.y = param2.y + (_loc7_ >> 1) - _loc5_.y;
               break;
            case AlignType.MIDDLE_RIGHT:
               param1.x = param2.x + _loc6_ - _loc5_.x;
               param1.y = param2.y + (_loc7_ >> 1) - _loc5_.y;
               break;
            case AlignType.BOTTOM_LEFT:
               param1.x = param2.x;
               param1.y = param2.y + _loc7_ - _loc5_.y;
               break;
            case AlignType.BOTTOM_CENTER:
               param1.x = param2.x + (_loc6_ >> 1) - _loc5_.x;
               param1.y = param2.y + _loc7_ - _loc5_.y;
               break;
            case AlignType.BOTTOM_RIGHT:
               param1.x = param2.x + _loc6_ - _loc5_.x;
               param1.y = param2.y + _loc7_ - _loc5_.y;
         }
      }
      
      public static function stop(param1:DisplayObject) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         if(param1 is MovieClip)
         {
            MovieClip(param1).stop();
         }
         if(param1 is DisplayObjectContainer)
         {
            _loc2_ = 0;
            _loc3_ = DisplayObjectContainer(param1).numChildren;
            while(_loc2_ < _loc3_)
            {
               stop(DisplayObjectContainer(param1).getChildAt(_loc2_));
               _loc2_++;
            }
         }
         else if(param1 is SimpleButton)
         {
            if(SimpleButton(param1).upState is DisplayObjectContainer)
            {
               stop(SimpleButton(param1).upState);
            }
            if(SimpleButton(param1).downState is DisplayObjectContainer)
            {
               stop(SimpleButton(param1).downState);
            }
            if(SimpleButton(param1).overState is DisplayObjectContainer)
            {
               stop(SimpleButton(param1).overState);
            }
            if(SimpleButton(param1).hitTestState is DisplayObjectContainer)
            {
               stop(SimpleButton(param1).hitTestState);
            }
         }
      }
      
      public static function stopAndRemove(param1:DisplayObject) : Boolean
      {
         var _loc2_:DisplayObjectContainer = null;
         if(param1 == null)
         {
            return false;
         }
         stop(param1);
         if(param1.parent != null)
         {
            _loc2_ = param1.parent;
            _loc2_.removeChild(param1);
            return true;
         }
         return false;
      }
      
      public static function scaleDisplay(param1:DisplayObject, param2:Number = 0, param3:Number = 0) : void
      {
         var _loc6_:Number = NaN;
         var _loc4_:Number = param2 / param1.width * param1.scaleX;
         var _loc5_:Number = param3 / param1.height * param1.scaleY;
         if(param2 > 0 && param3 > 0)
         {
            _loc6_ = _loc4_ < _loc5_ ? _loc4_ : _loc5_;
         }
         else if(param2 > 0)
         {
            _loc6_ = _loc4_;
         }
         else
         {
            if(param3 <= 0)
            {
               return;
            }
            _loc6_ = _loc5_;
         }
         param1.scaleX = _loc6_;
         param1.scaleY = _loc6_;
      }
      
      public static function middleDisplay(param1:DisplayObject, param2:Number, param3:Number) : void
      {
         param1.x = 0;
         param1.y = 0;
         var _loc4_:Rectangle = param1.getBounds(param1.parent);
         var _loc5_:Number = 0 - _loc4_.x;
         var _loc6_:Number = 0 - _loc4_.y;
         param1.x = (param2 - param1.width) / 2 + _loc5_;
         param1.y = (param3 - param1.height) / 2 + _loc6_;
      }
      
      public static function leftUpDisplay(param1:DisplayObject) : void
      {
         param1.x = 0;
         param1.y = 0;
         var _loc2_:Rectangle = param1.getBounds(param1.parent);
         var _loc3_:Number = 0 - _loc2_.x;
         var _loc4_:Number = 0 - _loc2_.y;
         param1.x = _loc3_;
         param1.y = _loc4_;
      }
      
      public static function setCenter(param1:Number, param2:Number, param3:DisplayObject, param4:int = 0) : void
      {
         var _loc5_:Number = param1 / param3.width;
         var _loc6_:Number = param2 / param3.height;
         if(_loc5_ < _loc6_)
         {
            param3.scaleX = _loc5_;
            param3.scaleY = _loc5_;
            param3.x = param4;
            param3.y = param4 + (param2 - param3.height) / 2;
         }
         else
         {
            param3.scaleY = _loc6_;
            param3.scaleX = _loc6_;
            param3.x = param4 + (param1 - param3.width) / 2;
            param3.y = param4;
         }
      }
      
      public static function fill(param1:Number, param2:Number, param3:DisplayObject, param4:Number = 0, param5:Boolean = true) : void
      {
         var _loc6_:Number = param1 - param4 * 2;
         var _loc7_:Number = param2 - param4 * 2;
         param3.transform.matrix = new Matrix();
         var _loc8_:Number = _loc6_ / param3.width;
         var _loc9_:Number = _loc7_ / param3.height;
         if(param5)
         {
            _loc9_ = _loc8_ = Math.min(_loc8_,_loc9_);
         }
         param3.scaleX = _loc8_;
         param3.scaleY = _loc9_;
         var _loc10_:Rectangle = param3.getBounds(param3);
         param3.x = -_loc10_.x + (param1 - param3.width) / 2;
         param3.y = -_loc10_.y + (param2 - param3.height) / 2;
      }
      
      public static function getMipmapValue(param1:int) : int
      {
         var _loc2_:* = param1 % 4;
         if(_loc2_ == 0)
         {
            return param1;
         }
         return param1 + (4 - _loc2_);
      }
      
      public static function applyAvatarGlow(param1:DisplayObject) : void
      {
         var _loc2_:Number = 0;
         var _loc3_:Number = 1;
         var _loc4_:Number = 1.2;
         var _loc5_:Number = 1.2;
         var _loc6_:Number = 2;
         var _loc7_:Boolean = false;
         var _loc8_:Boolean = false;
         var _loc9_:Number = BitmapFilterQuality.MEDIUM;
         var _loc10_:GlowFilter = new GlowFilter(_loc2_,_loc3_,_loc4_,_loc5_,_loc6_,_loc9_,_loc7_,_loc8_);
         var _loc11_:Array = new Array();
         _loc11_.push(_loc10_);
         param1.filters = _loc11_;
      }
      
      public static function alignDisplay(param1:DisplayObject, param2:DisplayObject, param3:String, param4:Boolean = false) : void
      {
         if(null == param1)
         {
            return;
         }
         if(null == param2 && null == param1.parent)
         {
            return;
         }
         if(null == param3)
         {
            return;
         }
         var _loc5_:String = "012";
         var _loc6_:Number = param1.x;
         var _loc7_:Number = param1.y;
         var _loc8_:DisplayObject = param1;
         var _loc9_:DisplayObject = param2;
         var _loc10_:String = param3.charAt(1);
         var _loc11_:String = param3.charAt(0);
         var _loc12_:Rectangle = getActualBounds(_loc9_);
         var _loc13_:Rectangle = getActualBounds(_loc8_);
         if(param4)
         {
            if(_loc5_.indexOf(_loc10_) != -1)
            {
               _loc8_.x = getAlignXBaseStage(_loc13_,_loc10_) - _loc13_.x;
            }
            if(_loc5_.indexOf(_loc11_) != -1)
            {
               _loc8_.y = getAlignYBaseStage(_loc13_,_loc11_) - _loc13_.y;
            }
         }
         else
         {
            if(_loc5_.indexOf(_loc10_) != -1)
            {
               _loc8_.x = getAlignX(_loc13_,_loc12_,_loc10_) - _loc13_.x;
            }
            if(_loc5_.indexOf(_loc11_) != -1)
            {
               _loc8_.y = getAlignY(_loc13_,_loc12_,_loc11_) - _loc13_.y;
            }
         }
      }
      
      public static function replaceAsBitmapMovieClip(param1:MovieClip, param2:Boolean = true) : BitmapMovieClip
      {
         var mcp:DisplayObjectContainer;
         var index:int;
         var mcX:Number;
         var mcY:Number;
         var bmmc:BitmapMovieClip = null;
         var onRemove:Function = null;
         var mc:MovieClip = param1;
         var autoRemoveDispose:Boolean = param2;
         if(mc == null)
         {
            return null;
         }
         mcp = mc.parent;
         index = -1;
         if(null != mcp)
         {
            index = mcp.getChildIndex(mc);
         }
         mcX = mc.x;
         mcY = mc.y;
         bmmc = new BitmapMovieClip(mc);
         if(-1 != index)
         {
            mcp.addChildAt(bmmc,index);
            bmmc.gotoAndPlay(1);
         }
         if(autoRemoveDispose)
         {
            onRemove = function(param1:Event):void
            {
               bmmc.removeEventListener(Event.REMOVED_FROM_STAGE,onRemove);
               bmmc.dispose();
            };
            bmmc.addEventListener(Event.REMOVED_FROM_STAGE,onRemove);
         }
         bmmc.x = mcX;
         bmmc.y = mcY;
         if(null != mc.name)
         {
            bmmc.name = mc.name;
         }
         return bmmc;
      }
      
      private static function getAlignYBaseStage(param1:Rectangle, param2:String) : Number
      {
         switch(param2)
         {
            case "0":
               return 0;
            case "1":
               return -param1.height / 2;
            case "2":
               return -param1.height;
            default:
               return 0;
         }
      }
      
      private static function getAlignXBaseStage(param1:Rectangle, param2:String) : Number
      {
         switch(param2)
         {
            case "0":
               return 0;
            case "1":
               return -param1.width / 2;
            case "2":
               return -param1.width;
            default:
               return 0;
         }
      }
      
      private static function getAlignX(param1:Rectangle, param2:Rectangle, param3:String) : Number
      {
         switch(param3)
         {
            case "0":
               return param2.x;
            case "1":
               return param2.x + (param2.width - param1.width) / 2;
            case "2":
               return param2.x + param2.width - param1.width;
            default:
               return 0;
         }
      }
      
      private static function getAlignY(param1:Rectangle, param2:Rectangle, param3:String) : Number
      {
         switch(param3)
         {
            case "0":
               return param2.y;
            case "1":
               return param2.y + (param2.height - param1.height) / 2;
            case "2":
               return param2.y + param2.height - param1.height;
            default:
               return 0;
         }
      }
      
      private static function setEvent(param1:DisplayObject, param2:Boolean) : void
      {
         if(param2)
         {
            param1.removeEventListener(Event.ADDED,onChangedByAddAndRemove,false);
            param1.removeEventListener(Event.REMOVED,onChangedByAddAndRemove,false);
            param1.removeEventListener(Event.ADDED_TO_STAGE,onChangedByAddAndRemove,false);
            param1.removeEventListener(Event.REMOVED_FROM_STAGE,onChangedByAddAndRemove,false);
         }
         else
         {
            param1.addEventListener(Event.ADDED,onChangedByAddAndRemove,false,int.MAX_VALUE);
            param1.addEventListener(Event.REMOVED,onChangedByAddAndRemove,false,int.MAX_VALUE);
            param1.addEventListener(Event.ADDED_TO_STAGE,onChangedByAddAndRemove,false,int.MAX_VALUE);
            param1.addEventListener(Event.REMOVED_FROM_STAGE,onChangedByAddAndRemove,false,int.MAX_VALUE);
         }
      }
      
      private static function applyFilter(param1:DisplayObject, param2:Array) : void
      {
         var _loc3_:ColorMatrixFilter = new ColorMatrixFilter(param2);
         var _loc4_:Array = new Array();
         _loc4_.push(_loc3_);
         param1.filters = _loc4_;
      }
      
      private static function onChangedByAddAndRemove(param1:Event) : void
      {
         param1.stopImmediatePropagation();
         param1.stopPropagation();
      }
      
      public static function setMouseEnabled(param1:*, param2:Boolean, param3:Boolean) : *
      {
         param1.mouseEnabled = param2;
         param1.mouseChildren = param3;
      }
      
      public static function clearChildren(param1:DisplayObjectContainer) : void
      {
         if(param1 == null)
         {
            return;
         }
         while(param1.numChildren > 0)
         {
            param1.removeChildAt(0);
         }
      }
   }
}

