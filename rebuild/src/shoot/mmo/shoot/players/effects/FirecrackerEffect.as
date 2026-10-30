package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.events.TimerEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.user.UserInfo;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   
   public class FirecrackerEffect extends PlayerEffectBase
   {
      
      private var startTimer:Timer;
      
      private var effect:PlayerEffectBase;
      
      public function FirecrackerEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.firecarkerEffect();
      }
      
      private function firecarkerEffect() : void
      {
         this.startCompute();
         this.effect = new ReplaceEffect(this.player,{
            "clothes":29975,
            "targetEffect":0
         });
         this.effect.apply();
         SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE,this.onUnLoadScene);
      }
      
      private function onUnLoadScene(param1:SceneManagerEvent) : void
      {
         if(this.player.name != UserInfo.userName)
         {
            this.dispose();
         }
      }
      
      private function startCompute() : void
      {
         this.startTimer = new Timer(1000 * 3,1);
         this.startTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onComplete);
         this.startTimer.start();
      }
      
      private function stopCompute() : void
      {
         if(this.startTimer != null)
         {
            this.startTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onComplete);
            this.startTimer.stop();
            this.startTimer = null;
         }
      }
      
      private function onComplete(param1:TimerEvent) : void
      {
         this.stopCompute();
         this.crakerEffect();
      }
      
      override public function get excludeKey() : String
      {
         return "FirecrackerEffect";
      }
      
      private function crakerEffect() : void
      {
         if(this.effect != null)
         {
            this.effect.dispose();
            this.effect = null;
         }
         if(this.player.visible)
         {
            if(Player(this.player).dressily.avatarSprite != null && Boolean(Player(this.player).dressily.avatarSprite.visible))
            {
               this.getCrackerEffectMovie();
            }
         }
      }
      
      private function getCrackerEffectMovie() : void
      {
         if(ApplicationDomain.currentDomain.hasDefinition("mmo.shoot.players.effects.FirecrakerMovie"))
         {
            this.addEffect();
         }
         else
         {
            ProgressFullSprite.show();
            ResScheduler.getResource("shoot/shootspecialeffectres",function(param1:DisplayObject):void
            {
               ProgressFullSprite.close();
               addEffect();
            });
         }
      }
      
      private function clearCrakerEffectMovie() : void
      {
         if(this.player == null)
         {
            return;
         }
         var _loc1_:MovieClip = this.player.getChildByName("shootEffectFirecraker") as MovieClip;
         if(_loc1_ != null)
         {
            DisplayUtil.stopAndRemove(_loc1_);
            if(Player(this.player) != null && Player(this.player).dressily != null && Player(this.player).dressily.avatarSprite != null)
            {
               Player(this.player).dressily.avatarSprite.visible = true;
            }
         }
         else if(this.effect != null)
         {
            this.effect.dispose();
            this.effect = null;
         }
      }
      
      private function addEffect() : void
      {
         var cls:Class;
         var mc:MovieClip;
         if(Player(this.player) == null || Player(this.player).dressily == null || Player(this.player).dressily.avatarSprite == null)
         {
            return;
         }
         cls = ApplicationDomain.currentDomain.getDefinition("mmo.shoot.players.effects.FirecrakerMovie") as Class;
         mc = new cls() as MovieClip;
         mc.name = "shootEffectFirecraker";
         Player(this.player).dressily.avatarSprite.visible = false;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            clearCrakerEffectMovie();
         });
         Player(this.player).addChild(mc);
      }
      
      override public function clear() : void
      {
         SceneManager.getInstance().removeEventListener(SceneManagerEvent.UNLOAD_SCENE,this.onUnLoadScene);
         this.stopCompute();
         this.clearCrakerEffectMovie();
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

