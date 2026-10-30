package mmo.shoot.effect.lighting
{
   import com.oaxoa.fx.Lightning;
   import com.oaxoa.fx.LightningFadeType;
   import flash.display.BlendMode;
   import flash.display.DisplayObjectContainer;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.filters.GlowFilter;
   import flash.utils.Timer;
   import mmo.interfaces.shoot.effects.IShootEffect;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   
   public class LightningEffect implements IShootEffect
   {
      
      private var _container:DisplayObjectContainer;
      
      private var _source:IShootEffectTarget;
      
      private var _target:IShootEffectTarget;
      
      private var _lightning:Lightning;
      
      public function LightningEffect(param1:DisplayObjectContainer)
      {
         super();
         this._container = param1;
      }
      
      public function shoot(param1:IShootEffectTarget, param2:IShootEffectTarget, param3:int = 1000) : void
      {
         var _loc4_:Timer = null;
         this._source = param1;
         this._target = param2;
         this.initLightning();
         this._container.addEventListener(Event.ENTER_FRAME,this.onEnterFrame,false,0);
         if(param3 > 0)
         {
            _loc4_ = new Timer(param3,1);
            _loc4_.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerCompleted,false,999);
            _loc4_.start();
         }
      }
      
      public function stop() : void
      {
         if(this._container == null)
         {
            return;
         }
         this._container.removeEventListener(Event.ENTER_FRAME,this.onEnterFrame);
         this._container = null;
         this._source.dispose();
         this._source = null;
         this._target.dispose();
         this._target = null;
         this.disposeLightning();
      }
      
      public function dispose() : void
      {
         this.stop();
      }
      
      private function updateLightning() : void
      {
         if(this._target == null || this._source == null)
         {
            return;
         }
         var _loc1_:Number = Number(this._target.x);
         var _loc2_:Number = Number(this._target.y);
         var _loc3_:Number = Math.random();
         if(_loc3_ < 0.3)
         {
            _loc1_ += Math.random() * 10 - 5;
            _loc2_ += Math.random() * 10 - 5;
         }
         var _loc4_:Number = this._source.x - _loc1_;
         var _loc5_:Number = this._source.y - _loc2_;
         var _loc6_:Number = Math.sqrt(_loc4_ * _loc4_ + _loc5_ * _loc5_);
         this._lightning.endX = _loc1_;
         this._lightning.endY = _loc2_;
         this._lightning.startX = this._source.x;
         this._lightning.startY = this._source.y;
         this._lightning.update();
      }
      
      private function onEnterFrame(param1:Event) : void
      {
         this.updateLightning();
      }
      
      private function onTimerCompleted(param1:TimerEvent) : void
      {
         var _loc2_:Timer = param1.target as Timer;
         _loc2_.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerCompleted);
         if(this._container != null)
         {
            this.stop();
         }
      }
      
      private function initLightning() : void
      {
         var _loc1_:uint = 16777215;
         this._lightning = new Lightning(_loc1_,2);
         this._lightning.blendMode = BlendMode.ADD;
         this._lightning.childrenDetachedEnd = false;
         this._lightning.childrenLifeSpanMin = 0.1;
         this._lightning.childrenLifeSpanMax = 2;
         this._lightning.childrenMaxCount = 4;
         this._lightning.childrenMaxCountDecay = 0.5;
         this._lightning.childrenProbability = 0.3;
         this._lightning.steps = 150;
         this._lightning.alphaFadeType = LightningFadeType.GENERATION;
         var _loc2_:GlowFilter = new GlowFilter();
         _loc2_.color = _loc1_;
         _loc2_.strength = 3.5;
         _loc2_.quality = 3;
         _loc2_.blurX = _loc2_.blurY = 10;
         this._lightning.filters = [_loc2_];
         this._container.addChild(this._lightning);
      }
      
      private function disposeLightning() : void
      {
         if(this._lightning == null)
         {
            return;
         }
         this._lightning.kill();
         this._lightning = null;
      }
   }
}

