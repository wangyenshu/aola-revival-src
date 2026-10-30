package mmo.shoot.effect
{
   import flash.events.EventDispatcher;
   import flash.geom.Point;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.effects.IShootEffectService;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.interfaces.shoot.effects.target.ShootForPoint;
   import mmo.play.player.PlayerManager;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.shoot.effect.effects.EffectDisplayer;
   import mmo.shoot.effect.helper.DirectionHelper;
   
   public class ShootEffectService extends EventDispatcher implements IShootEffectService
   {
      
      private var myCollectEffect:EffectDisplayer = null;
      
      public function ShootEffectService()
      {
         super();
      }
      
      public function shoot(param1:String, param2:int, param3:IShootEffectTarget, param4:ShootInfo, param5:Function = null, param6:* = null) : void
      {
         var onEffectDisplayed:Function;
         var effectDisplayer:EffectDisplayer = null;
         var fromUser:String = param1;
         var cardId:int = param2;
         var target:IShootEffectTarget = param3;
         var shootInfo:ShootInfo = param4;
         var callback:Function = param5;
         var thisObject:* = param6;
         var fromPlayer:PlayerBase = PlayerManager.getInstance().playerList[fromUser] as PlayerBase;
         if(fromPlayer == null)
         {
            return;
         }
         this.shootAction(fromPlayer,target,1500);
         effectDisplayer = new EffectDisplayer();
         onEffectDisplayed = function():void
         {
            effectDisplayer.dispose();
            if(callback != null)
            {
               callback.apply(thisObject);
            }
         };
         effectDisplayer.show(fromPlayer,target,cardId,shootInfo,onEffectDisplayed,this);
      }
      
      public function collect(param1:String, param2:Point, param3:int, param4:int, param5:Function = null, param6:* = null) : void
      {
         var target:IShootEffectTarget;
         var onEffectDisplayed:Function;
         var collectEffect:EffectDisplayer = null;
         var from:String = param1;
         var point:Point = param2;
         var cardId:int = param3;
         var duration:int = param4;
         var callback:Function = param5;
         var thisObject:* = param6;
         var fromPlayer:PlayerBase = PlayerManager.getInstance().playerList[from] as PlayerBase;
         if(fromPlayer == null)
         {
            return;
         }
         target = new ShootForPoint(point.x,point.y);
         this.shootAction(fromPlayer,target,duration);
         collectEffect = new EffectDisplayer();
         onEffectDisplayed = function():void
         {
            collectEffect.dispose();
            if(callback != null)
            {
               callback.apply(thisObject);
            }
            this.myCollectEffect = null;
         };
         collectEffect.show(fromPlayer,target,cardId,null,onEffectDisplayed,this,true,duration);
         if(from == SocketClient.instance.myUserName)
         {
            this.myCollectEffect = collectEffect;
         }
      }
      
      public function cancelCollect() : void
      {
         if(this.myCollectEffect == null)
         {
            return;
         }
         this.myCollectEffect.cancel();
      }
      
      private function shootAction(param1:PlayerBase, param2:IShootEffectTarget, param3:int) : void
      {
         // The later scene's actionHelper with priorities is not in the 2013
         // engine: the shooting pose ("dds" + the moving state n/f/r, in the
         // 2013 ActionInfo) is played on the player for param3 ms, then the
         // player stands again.
         var player:Player = param1 as Player;
         if(player == null)
         {
            return;
         }
         var current:String = player.currentAction();
         var state:String = current != null && current.length == 4 ? current.charAt(3) : "n";
         var dir:String = DirectionHelper.getDirection(param2.x - param1.x,param2.y - param1.y);
         var code:String = dir + "s" + state;
         player.action(code);
         var timer:Timer = new Timer(param3,1);
         timer.addEventListener(TimerEvent.TIMER,function(param1:TimerEvent):void
         {
            if(player.currentAction() == code)
            {
               player.action(dir + "z" + state);
            }
         });
         timer.start();
      }
   }
}

