package mmo.shoot.players.effects
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.filters.ColorMatrixFilter;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.sceneplayer.Player;
   import mmo.play.player.sceneplayer.PlayerBase;
   
   public class BossBurnEffect extends PlayerEffectBase
   {
      
      private static const CLASSNAME:String = "mmo.shoot.players.effects.BossBurnMovie";
      
      private static const MOVIENAME:String = "shootEffectBossBurnMovie_2012_10_31";
      
      public function BossBurnEffect(param1:PlayerBase, param2:Object)
      {
         super(param1,param2);
      }
      
      override public function apply() : void
      {
         this.setBurn(true);
      }
      
      private function setBurn(param1:Boolean) : void
      {
         this.setBurnEffect(param1);
      }
      
      private function setBurnEffect(param1:Boolean) : void
      {
         var _loc4_:Array = null;
         if(this.player == null)
         {
            return;
         }
         var _loc2_:DisplayObject = Player(this.player).dressily.avatarSprite as DisplayObject;
         var _loc3_:IShootService = ServiceContainer.getService(IShootService) as IShootService;
         if(param1)
         {
            _loc4_ = new Array();
            _loc4_ = _loc4_.concat([0.0317,0.0703,0.09,0,0]);
            _loc4_ = _loc4_.concat([0.0307,0.03753,0.09,0,0]);
            _loc4_ = _loc4_.concat([0.0307,0.0703,0.0589,0,0]);
            _loc4_ = _loc4_.concat([0,0,0,0.8,0]);
            this.applyFilter(_loc2_,_loc4_);
            if(this.isMe())
            {
               _loc3_.shootable = false;
            }
            this.burnEffect();
         }
         else
         {
            _loc2_.filters = null;
            if(this.isMe())
            {
               _loc3_.shootable = true;
               CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("BossEffectDispose_2012_11_1",{"type":0}));
            }
            this.clearBurnEffectMovie();
         }
      }
      
      private function burnEffect() : void
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
      
      private function clearBurnEffectMovie() : void
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
         mc.gotoAndPlay(21);
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
         mc.addFrameScript(19,function():void
         {
            mc.stop();
         });
         mc.gotoAndPlay(1);
         Player(this.player).addChild(mc);
      }
      
      private function applyFilter(param1:DisplayObject, param2:Array) : void
      {
         var _loc3_:ColorMatrixFilter = new ColorMatrixFilter(param2);
         var _loc4_:Array = new Array();
         _loc4_.push(_loc3_);
         param1.filters = _loc4_;
      }
      
      private function isMe() : Boolean
      {
         return this.player.getName() == PlayerManager.getInstance().myPlayer.getName();
      }
      
      override public function get excludeKey() : String
      {
         return "BossBurnEffect";
      }
      
      override public function clear() : void
      {
         this.setBurn(false);
      }
      
      override public function dispose() : void
      {
         this.clear();
         super.dispose();
      }
   }
}

