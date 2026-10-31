package mmo.spacetime
{
   import com.adobe.utils.NumberUtilities;
   import flash.display.DisplayObjectContainer;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import mmo.common.DisplayUtil;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.bubble.BubbleTypes;
   import mmo.common.utils.bubble.BubbleUtil;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.SpacetimeClient;
   import mmo.framework.comm.SpacetimeTClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.spacetime.ISpacetimeService;
   import mmo.interfaces.spacetime.SpacetimeEvent;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.play.player.PlayerManager;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitEvent;
   import mmo.play.scene.helper.cilckandhit.ClickAndHitHelper;
   import mmo.spacetime.pet.PetsBubbleConfig;
   import mmo.spacetime.pet.PetsConfig;
   
   public class NpcButton extends Sprite
   {
      
      private static const space:Number = 15;
      
      private static const multipleX:Number = 2.5;
      
      private var level:int;
      
      private var npcId:int;
      
      private var npcs:String;
      
      private var isClicking:Boolean = false;
      
      private var isFighting:Boolean = false;
      
      private var service:ISpacetimeService = null;
      
      private var ipfService:IPetFight = null;
      
      private var npcContainerAry:Array = [];
      
      private var bubbleAry:Array = null;
      
      private var bubbleType:int = -1;
      
      private var bubbleTimer:Timer = null;
      
      public function NpcButton(param1:int, param2:int, param3:String)
      {
         super();
         this.mouseEnabled = false;
         this.level = param1;
         this.npcId = param2;
         this.npcs = param3;
         this.addNpcButtons();
         this.addBubbles();
         this.service = ServiceContainer.getService(ISpacetimeService) as ISpacetimeService;
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onDispose);
      }
      
      private function addBubbles() : void
      {
         this.bubbleAry = PetsBubbleConfig.getBubbleArray(this.level);
         var _loc1_:int = this.getDirection();
         this.bubbleType = _loc1_ == -1 ? int(BubbleTypes.LEFT_TOP) : int(BubbleTypes.RIGHT_TOP);
         this.bubbleTimer = new Timer((PetsBubbleConfig.appearSecond + PetsBubbleConfig.disappearSecond + NumberUtilities.random(0,4,0.1)) * 1000);
         this.bubbleTimer.addEventListener(TimerEvent.TIMER,this.onTime);
         this.bubbleTimer.start();
         this.addBubble();
      }
      
      private function onTime(param1:TimerEvent) : void
      {
         this.addBubble();
      }
      
      private function addBubble() : void
      {
         var _loc1_:int = int(NumberUtilities.random(0,this.npcContainerAry.length - 1));
         var _loc2_:int = int(NumberUtilities.random(0,this.bubbleAry.length - 1));
         var _loc3_:Sprite = this.npcContainerAry[_loc1_] as Sprite;
         var _loc4_:String = this.bubbleAry[_loc2_] as String;
         BubbleUtil.instance.addBubble(_loc3_,[_loc4_],_loc3_.x,_loc3_.y - 110,PetsBubbleConfig.appearSecond,PetsBubbleConfig.disappearSecond,1,this.bubbleType,true);
      }
      
      private function addNpcButtons() : void
      {
         var _loc1_:Array = this.npcs.split("_");
         var _loc2_:int = this.getDirection();
         var _loc3_:int = _loc1_.length - 1;
         var _loc4_:* = _loc3_;
         while(_loc4_ >= 0)
         {
            this.addNpcButton(_loc2_,_loc4_,_loc1_,_loc3_);
            _loc4_--;
         }
      }
      
      private function addNpcButton(param1:int, param2:int, param3:Array, param4:int) : void
      {
         var _loc5_:Sprite = this.getNpcButton(param3[param2]);
         var _loc6_:int = param4 - param2;
         _loc5_.x = param1 * _loc6_ * space * multipleX;
         _loc5_.y = _loc6_ * space;
         _loc5_.scaleX = -param1;
         this.npcContainerAry.push(_loc5_);
         this.addChild(_loc5_);
         this.addListener(_loc5_);
      }
      
      private function getDirection() : int
      {
         var _loc1_:int = this.npcId % 2;
         if(0 == _loc1_)
         {
            return -1;
         }
         return 1;
      }
      
      private function getNpcButton(param1:int) : Sprite
      {
         var clsName:String = null;
         var rs:Sprite = null;
         var petId:int = param1;
         clsName = PetsConfig.getPetClsName(petId);
         rs = new Sprite();
         var cDomain:ApplicationDomain = ApplicationDomain.currentDomain;
         if(cDomain.hasDefinition(clsName))
         {
            this.containerAddChild(rs,clsName);
         }
         else
         {
            ResScheduler.getResource(PetsConfig.getPetResPath(petId),function(param1:*):void
            {
               containerAddChild(rs,clsName);
            });
         }
         return rs;
      }
      
      private function containerAddChild(param1:DisplayObjectContainer, param2:String) : void
      {
         if(!ApplicationDomain.currentDomain.hasDefinition(param2))
         {
            return;
         }
         var _loc3_:Class = getDefinitionByName(param2) as Class;
         var _loc4_:SimpleButton = new _loc3_() as SimpleButton;
         param1.addChild(_loc4_);
      }
      
      private function addListener(param1:Sprite) : void
      {
         ClickAndHitHelper.instance.registerTarget(param1,true,70);
         param1.addEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickAndHit);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onNpcButtonFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFallAction);
         SocketClient.instance.addEventListener(SpacetimeClient.cmdStartPK,this.onStartPK);
         SocketClient.instance.addEventListener(SpacetimeTClient.cmdStartPK,this.onStartPK);
      }
      
      private function onClickAndHit(param1:ClickAndHitEvent) : void
      {
         if(this.isClicking)
         {
            return;
         }
         this.isClicking = true;
         this.ipfService = ServiceContainer.getService(IPetFight) as IPetFight;
         this.ipfService.fightWithTowerPet(this.npcId);
      }
      
      private function onFallAction(param1:PetFightEvent) : void
      {
         PlayerManager.getInstance().myPlayer.stop();
         this.isClicking = false;
      }
      
      private function onStartPK(param1:SocketClientEvent) : void
      {
         PlayerManager.getInstance().myPlayer.stop();
         if(param1.params.enId == this.npcId)
         {
            this.isFighting = true;
         }
         else
         {
            this.isFighting = false;
         }
      }
      
      private function onNpcButtonFightEnd(param1:PetFightEvent) : void
      {
         if(this.isClicking)
         {
            this.isClicking = false;
         }
         if(this.isFighting)
         {
            if(param1.isWin)
            {
               if(this.service.liveNpcCount <= 0)
               {
                  this.service.liveNpcCount = 0;
               }
               else
               {
                  --this.service.liveNpcCount;
               }
               if(this.service.liveNpcCount == 0)
               {
                  this.service.updataInfo("door_open");
               }
               this.service.dispatchEvent(new SpacetimeEvent(SpacetimeEvent.LIVE_NPC_CHANGED,this.service.liveNpcCount));
               this.dispose();
            }
            else
            {
               this.service.updataInfo("check_Out");
            }
            this.isFighting = false;
         }
      }
      
      private function onDispose(param1:Event) : void
      {
         this.dispose();
      }
      
      private function dispose() : void
      {
         var _loc2_:Sprite = null;
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onDispose);
         this.bubbleTimer.stop();
         this.bubbleTimer.removeEventListener(TimerEvent.TIMER,this.onTime);
         SocketClient.instance.removeEventListener(SpacetimeTClient.cmdStartPK,this.onStartPK);
         SocketClient.instance.removeEventListener(SpacetimeClient.cmdStartPK,this.onStartPK);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onFallAction);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onNpcButtonFightEnd);
         this.ipfService = null;
         this.service = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.numChildren)
         {
            _loc2_ = this.getChildAt(_loc1_) as Sprite;
            ClickAndHitHelper.instance.remove(_loc2_);
            _loc2_.removeEventListener(ClickAndHitEvent.ON_CLICK_AND_HIT,this.onClickAndHit);
            _loc1_++;
         }
         DisplayUtil.stopAndRemove(this);
      }
   }
}

