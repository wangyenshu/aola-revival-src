package mmo.shoot.effect.beam
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class DoubleMoveDisplayer extends BeamDisplayerBase
   {
      
      public static const speed:int = 30;
      
      private var moved:Boolean = false;
      
      private var followBeam:MovieClip;
      
      private var followSteps:Array = [];
      
      private var cachStepCount:int = 0;
      
      private var distance:Number = -1;
      
      public function DoubleMoveDisplayer(param1:PlayerBase, param2:Point, param3:BeamInfo, param4:IShootEffectTarget, param5:int)
      {
         super(param1,param2,param3,param4,param5);
      }
      
      override public function show(param1:Function, param2:Function, param3:* = null) : void
      {
         super.show(param1,param2,param3);
         this.setInitPoint();
         this.followBeam = this.getBeam();
         this.followBeam.stop();
         this.followBeam.x = this.beam.x;
         this.followBeam.y = this.beam.y;
         this.setDirection();
         this.beam.addEventListener(Event.ENTER_FRAME,this.frame);
         this.followSteps = [];
         this.beam.parent.addChild(this.followBeam);
         var _loc4_:int = this.beam.parent.getChildIndex(this.beam) - 1;
         if(_loc4_ < 0)
         {
            _loc4_ = 0;
         }
         this.beam.parent.setChildIndex(this.followBeam,_loc4_);
         this.followBeam.rotation = this.beam.rotation;
         this.followBeam.width = this.beam.width;
         this.beam.gotoAndPlay(1);
         this.followBeam.gotoAndPlay(1);
      }
      
      private function setInitPoint() : void
      {
         var _loc5_:Number = NaN;
         var _loc1_:Number = target.x - initPoint.x;
         var _loc2_:Number = target.y - initPoint.y;
         var _loc3_:Number = Math.atan2(_loc2_,_loc1_);
         var _loc4_:Number = Math.sqrt(Math.pow(_loc1_,2) + Math.pow(_loc2_,2));
         if(_loc4_ < this.beam.width)
         {
            _loc5_ = _loc4_ - 10;
            if(_loc5_ < 0)
            {
               this.beam.width = 10;
            }
            else
            {
               this.beam.width = _loc4_ - 10;
            }
         }
         this.beam.x = this.beam.width * Math.cos(_loc3_) + initPoint.x;
         this.beam.y = this.beam.width * Math.sin(_loc3_) + initPoint.y;
      }
      
      private function frame(param1:Event) : void
      {
         if(this.moved)
         {
            DisplayUtil.stopAndRemove(this.beam);
         }
         else
         {
            this.setDirection();
            this.move();
         }
         if(this.moved && this.followSteps.length == 0)
         {
            this.beam.removeEventListener(Event.ENTER_FRAME,this.frame);
            this.onPlayed();
            return;
         }
         this.follow();
      }
      
      private function move() : *
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc1_:Number = this.target.x - this.beam.x;
         var _loc2_:Number = this.target.y - this.beam.y;
         var _loc3_:Number = Math.sqrt(Math.pow(_loc1_,2) + Math.pow(_loc2_,2));
         if(_loc3_ <= speed)
         {
            this.beam.x = this.target.x;
            this.beam.y = this.target.y;
            this.moved = true;
            this.onBump();
            this.followSteps.push(new FollowInfo(this.beam.x,this.beam.y,this.beam.rotation,this.beam.visible));
         }
         else
         {
            _loc4_ = speed;
            if(_loc4_ > _loc3_)
            {
               _loc4_ = _loc3_;
            }
            _loc5_ = _loc4_ * _loc1_ / _loc3_;
            _loc6_ = _loc4_ * _loc2_ / _loc3_;
            this.beam.x += _loc5_;
            this.beam.y += _loc6_;
         }
      }
      
      private function follow() : void
      {
         var _loc1_:FollowInfo = null;
         if(!this.moved)
         {
            this.followSteps.push(new FollowInfo(this.beam.x,this.beam.y,this.beam.rotation,this.beam.visible));
            ++this.cachStepCount;
         }
         if(this.cachStepCount > 4 && this.followSteps.length > 0 || this.moved)
         {
            _loc1_ = this.followSteps[0] as FollowInfo;
            this.followSteps.splice(0,1);
            this.followBeam.x = _loc1_.x;
            this.followBeam.y = _loc1_.y;
            this.followBeam.visible = this.beam.visible;
            this.followBeam.rotation = _loc1_.rotation;
         }
      }
      
      private function setDirection() : void
      {
         var _loc1_:Number = target.x - this.beam.x;
         var _loc2_:Number = target.y - this.beam.y;
         var _loc3_:Number = Math.atan2(_loc2_,_loc1_);
         this.beam.rotation = _loc3_ * 180 / Math.PI;
      }
      
      override protected function onPlayed() : void
      {
         DisplayUtil.stopAndRemove(this.followBeam);
         this.followBeam = null;
         super.onPlayed();
      }
   }
}

