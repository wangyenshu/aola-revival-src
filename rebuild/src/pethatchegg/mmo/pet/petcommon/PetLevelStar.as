package mmo.pet.petcommon
{
   import flash.display.*;
   
   public class PetLevelStar extends Sprite
   {
      
      public var s3:MovieClip;
      
      public var s4:MovieClip;
      
      private var starAry:Array = new Array();
      
      public var s0:MovieClip;
      
      public var s1:MovieClip;
      
      public var s2:MovieClip;
      
      public function PetLevelStar()
      {
         super();
         var _loc1_:int = 0;
         while(_loc1_ < 5)
         {
            this.starAry.push(this.getChildByName("s" + _loc1_) as MovieClip);
            MovieClip(this.getChildByName("s" + _loc1_)).gotoAndStop(1);
            _loc1_++;
         }
      }
      
      public function setLevel(param1:int) : void
      {
         var _loc3_:MovieClip = null;
         trace("llllllllllllllllllllll:" + param1);
         var _loc2_:int = 0;
         while(_loc2_ < this.starAry.length)
         {
            _loc3_ = this.starAry[_loc2_] as MovieClip;
            if(param1 == 5)
            {
               _loc3_.gotoAndStop(3);
            }
            else if(_loc2_ > param1 - 1)
            {
               _loc3_.gotoAndStop(1);
            }
            else
            {
               _loc3_.gotoAndStop(2);
            }
            _loc2_++;
         }
      }
      
      public function clear() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.starAry.length)
         {
            _loc2_ = this.starAry[_loc1_] as MovieClip;
            _loc2_.gotoAndStop(1);
            _loc1_++;
         }
      }
   }
}

