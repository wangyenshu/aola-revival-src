package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.movable.strategy.MouseControlStrategy;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneManager;
   
   public class IceFetterEffect extends PlayerEffectBase
   {
      
      private static const CLASSNAME:String = "mmo.shoot.players.effects.IceFetterMovie";
      
      private static const MOVIENAME:String = "shootEffectICEFetterMovie_2014_03_28";
      
      private static const URLNAME:String = "shoot/shoot_effect_2004";
      
      public function IceFetterEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setFetter(true);
      }
      
      private function setFetter(param1:Boolean) : void
      {
         this.setIceEffect(param1);
      }
      
      private function setIceEffect(param1:Boolean) : void
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
            }
            this.clearFetterEffectMovie();
         }
      }
      
      private function fetterEffect() : void
      {
         var domain:ApplicationDomain = null;
         if(SceneManager.getInstance().loadedSceneInfo == null)
         {
            return;
         }
         domain = SceneManager.getInstance().loadedSceneInfo.applicationDomain;
         if(domain.hasDefinition(CLASSNAME))
         {
            this.addEffect(domain);
         }
         else
         {
            ResScheduler.getResource(URLNAME,function(param1:DisplayObject):void
            {
               addEffect(domain);
            },CLASSNAME,null,null,ResPriority.NORMAL,true,domain);
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
         if(mc == null)
         {
            return;
         }
         mc.addFrameScript(mc.totalFrames - 1,function():void
         {
            DisplayUtil.stopAndRemove(mc);
         });
         mc.gotoAndPlay(57);
      }
      
      private function addEffect(param1:ApplicationDomain) : void
      {
         var cls:Class;
         var mc:MovieClip = null;
         var domain:ApplicationDomain = param1;
         if(this.player == null)
         {
            return;
         }
         cls = domain.getDefinition(CLASSNAME) as Class;
         mc = new cls() as MovieClip;
         mc.name = MOVIENAME;
         mc.addFrameScript(55,function():void
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
         return "IceFetterEffect";
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

