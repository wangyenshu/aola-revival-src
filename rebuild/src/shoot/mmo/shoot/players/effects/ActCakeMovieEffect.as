package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class ActCakeMovieEffect extends PlayerEffectBase
   {
      
      private static const CLASSNAME:String = "mmo.shoot.players.effects.CakeMovie";
      
      private static const MOVIENAME:String = "shootEffectCakeMovie_2013_03_28";
      
      public function ActCakeMovieEffect(param1:PlayerBase, param2:Object)
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
         }
         else
         {
            if(this.isMe())
            {
               player.setStrategy(new MouseControlStrategy());
               _loc3_.shootable = true;
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
            ResScheduler.getResource("shoot/shootspecialeffectres",this.addEffectByLoadFile);
         }
      }
      
      private function addEffectByLoadFile(param1:DisplayObject) : void
      {
         this.addEffect();
      }
      
      private function clearFetterEffectMovie() : void
      {
         if(Player(this.player) == null || Player(this.player).dressily == null || Player(this.player).dressily.avatarSprite == null)
         {
            return;
         }
         Player(this.player).dressily.avatarSprite.visible = true;
         var _loc1_:MovieClip = this.player.getChildByName(MOVIENAME) as MovieClip;
         DisplayUtil.stopAndRemove(_loc1_);
      }
      
      private function addEffect() : void
      {
         var cls:Class;
         var mc:MovieClip = null;
         if(Player(this.player) == null || Player(this.player).dressily == null || Player(this.player).dressily.avatarSprite == null)
         {
            return;
         }
         Player(this.player).dressily.avatarSprite.visible = false;
         cls = ApplicationDomain.currentDomain.getDefinition(CLASSNAME) as Class;
         mc = new cls() as MovieClip;
         mc.name = MOVIENAME;
         mc.addFrameScript(mc.totalFrames - 1,function():void
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
         return "ActCakeMovieEffect";
      }
      
      override public function clear() : void
      {
         ResScheduler.cancel("shoot/shootspecialeffectres",this.addEffectByLoadFile);
         this.setFetter(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

