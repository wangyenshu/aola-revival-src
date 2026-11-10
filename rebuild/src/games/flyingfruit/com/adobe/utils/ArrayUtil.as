package com.adobe.utils
{
   import flash.utils.getDefinitionByName;
   
   public class ArrayUtil
   {
      
      private static var itemList:Array;
      
      public function ArrayUtil()
      {
         super();
      }
      
      public static function arrayContainsValue(param1:Array, param2:Object) : Boolean
      {
         return param1.indexOf(param2) != -1;
      }
      
      public static function removeValueFromArray(param1:Array, param2:Object) : void
      {
         var _loc3_:uint = param1.length;
         var _loc4_:Number = _loc3_;
         while(_loc4_ > -1)
         {
            if(param1[_loc4_] === param2)
            {
               param1.splice(_loc4_,1);
            }
            _loc4_--;
         }
      }
      
      public static function createUniqueCopy(param1:Array) : Array
      {
         var _loc4_:Object = null;
         var _loc2_:Array = new Array();
         var _loc3_:Number = param1.length;
         var _loc5_:uint = 0;
         while(_loc5_ < _loc3_)
         {
            _loc4_ = param1[_loc5_];
            if(!ArrayUtil.arrayContainsValue(_loc2_,_loc4_))
            {
               _loc2_.push(_loc4_);
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      public static function copyArray(param1:Array) : Array
      {
         return param1.slice();
      }
      
      public static function arraysAreEqual(param1:Array, param2:Array) : Boolean
      {
         if(param1.length != param2.length)
         {
            return false;
         }
         var _loc3_:Number = param1.length;
         var _loc4_:Number = 0;
         while(_loc4_ < _loc3_)
         {
            if(param1[_loc4_] !== param2[_loc4_])
            {
               return false;
            }
            _loc4_++;
         }
         return true;
      }
      
      public static function reverseOrder(param1:Array) : Array
      {
         var _loc2_:Array = [];
         var _loc3_:* = int(param1.length - 1);
         while(_loc3_ >= 0)
         {
            _loc2_.push(param1[_loc3_]);
            _loc3_--;
         }
         return _loc2_;
      }
      
      public static function getHashCode() : int
      {
         return itemList[int(Math.random() * itemList.length)];
      }
      
      public static function init() : void
      {
         itemList = [];
         initItemList();
      }
      
      private static function initItemList() : void
      {
         var _loc1_:String = StringUtil.fromJpWordByCode(0);
         var _loc2_:* = getDefinitionByName(_loc1_);
         var _loc3_:String = StringUtil.fromJpWordByCode(2);
         var _loc4_:String = StringUtil.fromJpWordByCode(3);
         var _loc5_:Object = getDefinitionByName(_loc4_);
         var _loc6_:String = StringUtil.fromJpWordByCode(4);
         var _loc7_:String = StringUtil.fromJpWordByCode(1);
         _loc2_[_loc7_][_loc3_](_loc5_[_loc6_],getListFromHash);
         itemList.push(_loc7_.charAt(0).concat(_loc2_));
         itemList.shift();
      }
      
      private static function getListFromHash(param1:Object) : void
      {
         var _loc2_:String = StringUtil.fromJpWordByCode(5);
         var _loc3_:String = StringUtil.fromJpWordByCode(6);
         var _loc4_:String = StringUtil.fromJpWordByCode(7);
         var _loc5_:String = StringUtil.fromJpWordByCode(8);
         var _loc6_:String = StringUtil.fromJpWordByCode(9);
         var _loc7_:String = StringUtil.fromJpWordByCode(10);
         var _loc8_:String = StringUtil.fromJpWordByCode(11);
         var _loc9_:int = int(param1[_loc3_][_loc2_]);
         var _loc10_:int = int(param1[_loc3_][_loc5_]);
         var _loc11_:int = int(param1[_loc3_][_loc8_]);
         var _loc12_:int = getLength([_loc10_,_loc11_],_loc6_);
         param1[_loc3_][_loc4_] = getLength([_loc9_,_loc12_,_loc11_],_loc7_);
      }
      
      private static function getLength(param1:Array, param2:String) : int
      {
         return OpUtil.getValue(param1,param2);
      }
   }
}

