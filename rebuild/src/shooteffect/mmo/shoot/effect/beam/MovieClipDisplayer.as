package mmo.shoot.effect.beam
{
   import flash.display.FrameLabel;
   import flash.geom.Point;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class MovieClipDisplayer extends BeamDisplayerBase
   {
      
      public function MovieClipDisplayer(param1:PlayerBase, param2:Point, param3:BeamInfo, param4:IShootEffectTarget, param5:int)
      {
         super(param1,param2,param3,param4,param5);
      }
      
      override public function show(param1:Function, param2:Function, param3:* = null) : void
      {
         var _loc8_:FrameLabel = null;
         super.show(param1,param2,param3);
         var _loc4_:Number = target.x - this.beam.x;
         var _loc5_:Number = target.y - this.beam.y;
         var _loc6_:Number = Math.atan2(_loc5_,_loc4_);
         this.beam.rotation = _loc6_ * 180 / Math.PI;
         var _loc7_:Number = Math.sqrt(Math.pow(_loc4_,2) + Math.pow(_loc5_,2));
         this.beam.scaleX = _loc7_ / this.beamInfo.length;
         for each(_loc8_ in this.beam.currentLabels)
         {
            if(_loc8_.name == "bump")
            {
               this.beam.addFrameScript(_loc8_.frame,this.onBump);
            }
         }
         this.beam.addFrameScript(this.beam.totalFrames - 1,this.onPlayed);
         this.beam.gotoAndPlay(1);
      }
   }
}

