package mmo.shoot.effect.beam
{
   import flash.events.Event;
   import flash.geom.Point;
   import flash.utils.getTimer;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class CollectMoveDisplayer extends BeamDisplayerBase
   {
      
      private var startTime:int;
      
      public function CollectMoveDisplayer(param1:PlayerBase, param2:Point, param3:BeamInfo, param4:IShootEffectTarget, param5:int)
      {
         super(param1,param2,param3,param4,param5);
      }
      
      override public function show(param1:Function, param2:Function, param3:* = null) : void
      {
         super.show(param1,param2,param3);
         this.setBeam();
         this.startTime = getTimer();
         this.beam.addEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this.beam.gotoAndPlay(1);
      }
      
      private function onEnterFrame(param1:Event) : void
      {
         if(this.beam == null)
         {
            return;
         }
         if(getTimer() - this.startTime >= this.duration)
         {
            this.beam.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
            DisplayUtil.stopAndRemove(this.beam);
            this.onBump();
            this.onPlayed();
         }
      }
      
      private function setBeam() : void
      {
         var _loc1_:Number = target.x - this.beam.x;
         var _loc2_:Number = target.y - this.beam.y;
         var _loc3_:Number = Math.atan2(_loc2_,_loc1_);
         this.beam.rotation = _loc3_ * 180 / Math.PI;
         var _loc4_:Number = Math.sqrt(Math.pow(_loc1_,2) + Math.pow(_loc2_,2));
      }
      
      override protected function disopse() : void
      {
         this.beam.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         super.disopse();
      }
   }
}

