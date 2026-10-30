package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class BossFetterEffect extends PlayerEffectBase
   {
      
      private static const CLASSNAME:String = "mmo.shoot.players.effects.FetterMovie";
      
      private static const MOVIENAME:String = "shootEffectFetterMovie_2012_10_31";
      
      public function BossFetterEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setFetter(true);
      }
      
      private function setFetter(param1:Boolean) : void
      {
         this.setBurnEffect(param1);
      }
      
      private function setBurnEffect(param1:Boolean) : void
      {
         if(this.player == null)
         {
            return;
         }
         var _loc2_:DisplayObject = Player(this.player).dressily.avatarSprite as DisplayObject;
         var _loc3_:IShootService = ServiceContainer.getService(IShootService) as IShootService;
         if(param1)
         {
            this.fetterEffect();
            if(this.isMe())
            {
               player.setStrategy(null);
               _loc3_.shootable = false;
            }
         }
         else
         {
            if(this.isMe())
            {
               player.setStrategy(new MouseControlStrategy());
               _loc3_.shootable = true;
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("BossEffectDispose_2012_11_1",{"type":1}));
            }
            this.clearFetterEffectMovie();
         }
      }
      
      private function fetterEffect() : void
      {
         if(ApplicationDomain.currentDomain.hasDefinition(CLASSNAME))
         {
            this.addEffect();
         }
         else
         {
            ResScheduler.getResource("shoot/shootspecialeffectres",function(param1:DisplayObject):void
            {
               addEffect();
            });
         }
      }
      
      private function clearFetterEffectMovie() : void
      {
         var mc:MovieClip = null;
         if(this.player == null)
         {
            return;
         }
         mc = this.player.getChildByName(MOVIENAME) as MovieClip;
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(mc);
         });
         mc.gotoAndPlay(32);
      }
      
      private function addEffect() : void
      {
         var cls:Class;
         var mc:MovieClip = null;
         if(this.player == null)
         {
            return;
         }
         cls = ApplicationDomain.currentDomain.getDefinition(CLASSNAME) as Class;
         mc = new cls() as MovieClip;
         mc.name = MOVIENAME;
         mc.addFrameScript(30,function():void
         {
            mc.stop();
         });
         mc.gotoAndPlay(1);
         Player(this.player).addChild(mc);
      }
      
      private function isMe() : Boolean
      {
         return this.player.getName() == PlayerManager.getInstance().myPlayer.getName();
      }
      
      override public function get excludeKey() : String
      {
         return "BossFetterEffect";
      }
      
      override public function clear() : void
      {
         this.setFetter(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

