package mmo.shoot.effect.effects
{
   import flash.display.MovieClip;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.ShootTargetTypes;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   import mmo.shoot.effect.beam.BeamDisplayerBase;
   import mmo.shoot.effect.beam.BeamDisplayerFactory;
   import mmo.shoot.effect.beam.BeamInfo;
   
   public class EffectDisplayer implements IDispose
   {
      
      private static const ShootEffectPoint:Point = new Point(0,-48);
      
      private static const ShootEffectRadii:int = 50;
      
      private var player:PlayerBase;
      
      private var target:IShootEffectTarget;
      
      private var cardId:int;
      
      private var callback:Function;
      
      private var thisObject:*;
      
      private var shootEffect:ShootEffectBase;
      
      private var beamDisplayer:BeamDisplayerBase;
      
      private var shootInfo:ShootInfo;
      
      private var collect:Boolean = false;
      
      private var collectDuration:int;
      
      private var cards:Array = [1,2];
      
      public function EffectDisplayer()
      {
         super();
      }
      
      public function show(param1:PlayerBase, param2:IShootEffectTarget, param3:int, param4:ShootInfo, param5:Function, param6:*, param7:Boolean = false, param8:int = 0) : void
      {
         this.player = param1;
         this.target = param2;
         this.cardId = param3;
         this.shootInfo = param4;
         this.callback = param5;
         this.thisObject = param6;
         this.collect = param7;
         this.collectDuration = param8;
         this.showEffect();
      }
      
      private function showEffect() : void
      {
         var onPlayed:Function;
         var dx:Number = this.target.x - this.player.x;
         var dy:Number = this.target.y - this.player.y;
         var angle:Number = Math.atan2(dy,dx);
         this.shootEffect = EffectManager.instance.getShootEffect(this.cardId,this.collect);
         this.shootEffect.x = Math.cos(angle) * ShootEffectRadii + ShootEffectPoint.x;
         this.shootEffect.y = Math.sin(angle) * ShootEffectRadii + ShootEffectPoint.y;
         this.shootEffect.rotation = angle * 180 / Math.PI;
         this.player.addChild(this.shootEffect);
         if(angle < 0)
         {
            this.player.setChildIndex(this.shootEffect,0);
         }
         onPlayed = function onShootEffectPlayed():*
         {
            DisplayUtil.stop(this.shootEffect);
            this.showBeam(player,shootEffect);
         };
         this.shootEffect.show(onPlayed,this);
      }
      
      private function showBeam(param1:PlayerBase, param2:MovieClip) : void
      {
         var onBump:Function;
         var onPlayed:Function;
         var fromPoint:Point = null;
         var player:PlayerBase = param1;
         var shootEffect:MovieClip = param2;
         var beamInfo:BeamInfo = EffectManager.instance.getBeam(this.cardId,this.collect);
         fromPoint = new Point(player.x + shootEffect.x,player.y + shootEffect.y);
         this.beamDisplayer = BeamDisplayerFactory.getDisplayer(player,fromPoint,beamInfo,this.target,this.collectDuration);
         onBump = function():void
         {
            DisplayUtil.stopAndRemove(shootEffect);
            this.shootEffect = null;
            if(!this.collect)
            {
               this.showBumpEffect(player,fromPoint);
            }
         };
         onPlayed = function onBeamPlayed():*
         {
            if(this.callback != null)
            {
               this.callback.apply(thisObject);
            }
            DisplayUtil.stopAndRemove(shootEffect);
         };
         this.beamDisplayer.show(onBump,onPlayed,this);
      }
      
      private function showBumpEffect(param1:PlayerBase, param2:Point) : void
      {
         var dx:Number;
         var dy:Number;
         var angle:Number;
         var bumpEffect:MovieClip = null;
         var targetPlayer:PlayerBase = null;
         var player:PlayerBase = param1;
         var fromPoint:Point = param2;
         if(null == player)
         {
            return;
         }
         if(player.parent == null)
         {
            return;
         }
         bumpEffect = EffectManager.instance.getBumpEffect(this.cardId);
         if(bumpEffect == null)
         {
            return;
         }
         if(SceneManager.getInstance().loadedSceneInfo == null)
         {
            DisplayUtil.stopAndRemove(bumpEffect);
            return;
         }
         bumpEffect.x = this.target.x;
         bumpEffect.y = this.target.y;
         bumpEffect.mouseChildren = false;
         bumpEffect.mouseEnabled = false;
         dx = this.target.x - fromPoint.x;
         dy = this.target.y - fromPoint.y;
         angle = Math.atan2(dy,dx);
         if(this.needRotation(this.cardId))
         {
            bumpEffect.rotation = angle * 180 / Math.PI;
            if(angle < 0)
            {
               player.parent.addChildAt(bumpEffect,player.parent.getChildIndex(player));
            }
            else
            {
               player.parent.addChildAt(bumpEffect,player.parent.getChildIndex(player) + 1);
            }
         }
         else if(this.cards.indexOf(this.cardId) != -1 && this.shootInfo != null && this.shootInfo.targetType == ShootTargetTypes.Player)
         {
            bumpEffect = EffectManager.instance.getEffectMovie(this.cardId);
            targetPlayer = PlayerManager.getInstance().playerList[this.shootInfo.target] as PlayerBase;
            if(targetPlayer != null)
            {
               targetPlayer.addChild(bumpEffect);
            }
         }
         else
         {
            SceneManager.getInstance().loadedSceneInfo.scene.foreGround.addChild(bumpEffect);
         }
         bumpEffect.addFrameScript(bumpEffect.totalFrames - 1,function():*
         {
            DisplayUtil.stopAndRemove(bumpEffect);
         });
         bumpEffect.gotoAndPlay(1);
      }
      
      private function needRotation(param1:int) : Boolean
      {
         var _loc2_:Boolean = false;
         return param1 < 10000 && this.cards.indexOf(param1) == -1;
      }
      
      public function cancel() : void
      {
         if(this.shootEffect != null)
         {
            DisplayUtil.stopAndRemove(this.shootEffect);
         }
         if(this.beamDisplayer != null)
         {
            this.beamDisplayer.cancel();
            this.beamDisplayer = null;
         }
         this.dispose();
      }
      
      public function dispose() : void
      {
         this.player = null;
         this.target = null;
         this.callback = null;
         this.thisObject = null;
         this.shootEffect = null;
         this.beamDisplayer = null;
      }
   }
}

