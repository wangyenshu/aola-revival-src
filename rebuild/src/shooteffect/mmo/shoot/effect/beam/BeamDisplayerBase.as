package mmo.shoot.effect.beam
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.common.user.UserInfo;
   import mmo.interfaces.shoot.effects.IBeamEffectWithSound;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class BeamDisplayerBase
   {
      
      protected var beamInfo:BeamInfo;
      
      protected var beam:MovieClip;
      
      protected var initPoint:Point;
      
      protected var duration:int;
      
      protected var target:IShootEffectTarget;
      
      private var onBumpCallback:Function;
      
      private var onPlayedCallback:Function;
      
      private var thisObject:*;
      
      private var playerName:String;
      
      public function BeamDisplayerBase(param1:PlayerBase, param2:Point, param3:BeamInfo, param4:IShootEffectTarget, param5:int)
      {
         super();
         this.duration = param5;
         this.initPoint = param2;
         this.beamInfo = param3;
         this.playerName = param1.getName();
         this.beam = this.getBeam();
         this.beam.stop();
         this.beam.x = param2.x;
         this.beam.y = param2.y;
         this.target = param4;
         var _loc6_:Number = param4.x - param2.x;
         var _loc7_:Number = param4.y - param2.y;
         var _loc8_:Number = Math.atan2(_loc7_,_loc6_);
         if(_loc8_ < 0)
         {
            param1.parent.addChildAt(this.beam,param1.parent.getChildIndex(param1));
         }
         else
         {
            param1.parent.addChildAt(this.beam,param1.parent.getChildIndex(param1) + 1);
         }
      }
      
      public function show(param1:Function, param2:Function, param3:* = null) : void
      {
         this.onBumpCallback = param1;
         this.onPlayedCallback = param2;
         this.thisObject = param3;
      }
      
      public function cancel() : void
      {
         this.disopse();
      }
      
      protected function onPlayed() : void
      {
         this.disopse();
         this.onPlayedCallback.apply(this.thisObject);
      }
      
      protected function onBump() : void
      {
         this.onBumpCallback.apply(this.thisObject);
      }
      
      protected function getBeam() : MovieClip
      {
         var _loc1_:Class = getDefinitionByName(this.beamInfo.type) as Class;
         var _loc2_:MovieClip = new _loc1_() as MovieClip;
         if(_loc2_ is IBeamEffectWithSound && UserInfo.userName == this.playerName)
         {
            IBeamEffectWithSound(_loc2_).initSound();
         }
         return _loc2_;
      }
      
      protected function disopse() : void
      {
         DisplayUtil.stopAndRemove(this.beam);
         this.playerName = null;
         this.beam = null;
         this.beamInfo = null;
         this.target = null;
      }
   }
}

