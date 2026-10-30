package mmo.shoot
{
   import flash.display.DisplayObject;
   import flash.display.InteractiveObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.ui.Mouse;
   import flash.utils.Timer;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.user.UserInfo;
   import mmo.common.viewloader.ViewContainer;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.gather.IGatherService;
   import mmo.interfaces.material.AbstractMaterialService;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.UserMaterial;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.ShootServiceEvent;
   import mmo.interfaces.shoot.data.ShootCard;
   import mmo.interfaces.shoot.data.ShootInfo;
   import mmo.interfaces.shoot.data.TargetInfo;
   import mmo.interfaces.shoot.data.UserShootCard;
   import mmo.interfaces.shoot.effects.IShootEffectService;
   import mmo.interfaces.shoot.effects.IShootEffectTarget;
   import mmo.interfaces.shoot.handler.IShootTargetHandler;
   import mmo.loader.LoaderContainer;
   import mmo.play.player.PlayerManager;
   import mmo.play.player.PlayerManagerEvent;
   import mmo.play.player.sceneplayer.PlayerBase;
   import mmo.play.scene.SceneInfo;
   import mmo.play.scene.SceneManager;
   import mmo.play.scene.SceneManagerEvent;
   import mmo.shoot.client.ShootClient;
   import mmo.shoot.data.CardData;
   import mmo.shoot.players.PlayerTargetManager;
   import mmo.shoot.shootbar.ShootButtonWrap;
   import mmo.socketserver.data.User;
   
   public class ShootService extends AbstractMaterialService implements IShootService
   {
      
      public static var instance:ShootService;
      
      private static const TargetEffectKey:String = "shoot_effect";
      
      public static const CrystalEnergyId:int = 5;
      
      private var _shootable:Boolean = true;
      
      private var handlerManager:HandlerManager;
      
      private var readyCardId:int = 0;
      
      private var isNeedDelay:Boolean = false;
      
      private var _isImmuneFromEffect:Boolean = false;
      
      private var targetIcon:DisplayObject;
      
      private var shootcardFilter:Array = [];
      
      private var filterNotice:String = "";
      
      private var autoUnReady:Boolean = true;
      
      public function ShootService()
      {
         super();
         instance = this;
      }
      
      override public function getNewUserMaterial(param1:int, param2:int, param3:int) : UserMaterial
      {
         var _loc4_:ShootCard = this.getCard(param1);
         return new UserShootCard(_loc4_,param2);
      }
      
      override public function init() : void
      {
         this.handlerManager = new HandlerManager();
         this.materialsMap = CardData.datas;
         SocketClient.instance.addEventListener(ShootClient.onGetMyCards,this.onGetMyCards);
         ShootClient.instance.getMyCards();
         SocketClient.instance.addEventListener("ShootCardGained",this.onGained);
         this.onInited();
      }
      
      private function onGained(param1:SocketClientEvent) : void
      {
         var _loc5_:String = null;
         var _loc6_:Array = null;
         var _loc2_:String = param1.params.c;
         if(_loc2_ == null || _loc2_ == "")
         {
            return;
         }
         var _loc3_:Array = _loc2_.split(";");
         var _loc4_:IMaterialGetPanel = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
         for each(_loc5_ in _loc3_)
         {
            _loc6_ = _loc5_.split(":");
            if(_loc6_.length < 3)
            {
               return;
            }
            if(_loc6_[0] == 101)
            {
               _loc4_.showGettedExpPanel(int(_loc6_[2]));
            }
            else if(_loc6_[0] == 100)
            {
               _loc4_.showGettedMoneyPanel(_loc6_[2]);
            }
            else
            {
               _loc4_.showPanel(int(_loc6_[0]),int(_loc6_[1]),int(_loc6_[2]));
            }
         }
      }
      
      private function onGetMyCards(param1:SocketClientEvent) : void
      {
         var cardInfos:Array = null;
         var cardInfo:Object = null;
         var card:ShootCard = null;
         var evt:SocketClientEvent = param1;
         try
         {
            SocketClient.instance.removeEventListener(ShootClient.onGetMyCards,this.onGetMyCards);
            cardInfos = evt.params.cards;
            for each(cardInfo in cardInfos)
            {
               card = this.getCard(cardInfo.i);
               this.addMyMaterial(new UserShootCard(card,cardInfo.q));
            }
            SocketClient.instance.addEventListener(ShootClient.onTargetValidate,this.onTargetValidate);
            SocketClient.instance.addEventListener(ShootClient.onBump,this.onBump);
            SocketClient.instance.addEventListener(SocketClientEvent.onUserVariablesUpdate,this.onUserVariablesUpdate);
            PlayerTargetManager.instance.init();
            PlayerManager.getInstance().addEventListener(PlayerManagerEvent.ENTER_ROOM,this.onUserEnter);
            SceneManager.getInstance().addEventListener(SceneManagerEvent.UNLOAD_SCENE,this.onUnloadScene);
         }
         catch(e:Error)
         {
            SocketClient.instance.clientDebug(e.getStackTrace());
         }
      }
      
      public function set shootable(param1:Boolean) : void
      {
         this._shootable = param1;
         if(!this._shootable)
         {
            this.unReady();
         }
      }
      
      public function get shootable() : Boolean
      {
         var _loc1_:IGatherService = ServiceContainer.getService(IGatherService) as IGatherService;
         return this._shootable && !_loc1_.isCollecting;
      }
      
      public function registerTarget(param1:IShootTargetHandler) : void
      {
         this.handlerManager.registerHandler(param1);
      }
      
      public function registerDefaultTarget(param1:TargetInfo) : void
      {
         var _loc2_:DefaultTargetHandler = new DefaultTargetHandler(param1);
         this.handlerManager.registerHandler(_loc2_);
      }
      
      public function removeTarget(param1:int, param2:String) : void
      {
         this.handlerManager.removeTarget(param1,param2);
      }
      
      public function clearTarget() : void
      {
         this.handlerManager.clearTarget();
      }
      
      public function shootReady(param1:int, param2:DisplayObject = null, param3:Boolean = true) : void
      {
         if(!this.validateShoot(param1))
         {
            return;
         }
         if(this.readyCardId == 0)
         {
            this.showCursor(param2);
         }
         this.readyCardId = param1;
         this.autoUnReady = param3;
      }
      
      public function shootReadWithoutIcon(param1:int, param2:Boolean = true) : void
      {
         if(!this.validateShoot(param1))
         {
            return;
         }
         this.readyCardId = param1;
         this.autoUnReady = param2;
      }
      
      private function validateShoot(param1:int) : Boolean
      {
         if(!this.shootable)
         {
            return false;
         }
         if(!this.hasMaterial(param1))
         {
            return false;
         }
         return true;
      }
      
      private function haveEnoughEnergyCrystal() : Boolean
      {
         var _loc1_:IItemService = ServiceContainer.instance.getService(IItemService) as IItemService;
         var _loc2_:UserItem = _loc1_.getMyItemById(CrystalEnergyId);
         if(_loc2_ == null || _loc2_.available < 1)
         {
            return false;
         }
         return true;
      }
      
      private function showCursor(param1:DisplayObject = null) : void
      {
         Mouse.hide();
         this.targetIcon = null;
         if(param1 == null)
         {
            this.targetIcon = TargetIcon.instance;
         }
         else
         {
            this.targetIcon = param1;
         }
         if(this.targetIcon is InteractiveObject)
         {
            InteractiveObject(this.targetIcon).mouseEnabled = false;
         }
         var _loc2_:int = int(LoaderContainer.instance.stage.mouseX);
         var _loc3_:int = int(LoaderContainer.instance.stage.mouseY);
         this.targetIcon.x = _loc2_;
         this.targetIcon.y = _loc3_;
         LoaderContainer.instance.stage.addChild(this.targetIcon);
         LoaderContainer.instance.addEventListener(Event.ENTER_FRAME,this.onFrame_Cursor);
      }
      
      private function onFrame_Cursor(param1:Event) : void
      {
         if(this.targetIcon == null)
         {
            return;
         }
         var _loc2_:int = int(LoaderContainer.instance.stage.mouseX);
         var _loc3_:int = int(LoaderContainer.instance.stage.mouseY);
         this.targetIcon.x = _loc2_;
         this.targetIcon.y = _loc3_;
      }
      
      private function removeCursor() : void
      {
         Mouse.show();
         if(this.targetIcon != null && this.targetIcon.parent != null)
         {
            LoaderContainer.instance.stage.removeChild(this.targetIcon);
         }
         LoaderContainer.instance.removeEventListener(Event.ENTER_FRAME,this.onFrame_Cursor);
      }
      
      public function get isReady() : Boolean
      {
         if(this.readyCardId != 0)
         {
            return true;
         }
         return false;
      }
      
      public function unReady() : void
      {
         this.autoUnReady = true;
         if(this.readyCardId == 0)
         {
            return;
         }
         this.readyCardId = 0;
         this.removeCursor();
      }
      
      public function shoot(param1:TargetInfo) : void
      {
         if(!this.isReady || !this.shootable)
         {
            return;
         }
         var _loc2_:Object = {
            "cancel":false,
            "readyCardId":this.readyCardId
         };
         this.dispatchEvent(new ShootServiceEvent(ShootServiceEvent.onWillShoot,_loc2_));
         if(_loc2_.cancel)
         {
            return;
         }
         this.isNeedDelay = true;
         PlayerManager.getInstance().myPlayer.stop();
         ShootClient.instance.fire(this.readyCardId,param1.targetName,param1.targetType,param1.point.x,param1.point.y,null,this.getSubSocketClient());
         CommonEventDispatcher.instance.dispatchEvent(new Event("SHOOT_START"));
         if(this.autoUnReady)
         {
            this.readyCardId = 0;
            this.removeCursor();
         }
      }
      
      private function getSubSocketClient() : Object
      {
         // The 2013 client has no scene sub-sockets: everything goes on the one socket.
         return null;
      }
      
      private function onTargetValidate(param1:SocketClientEvent) : void
      {
         var _loc2_:ShootInfo = new ShootInfo();
         _loc2_.parse(param1.params.info);
         if(_loc2_.roomId != SocketClient.instance.activeRoomId)
         {
            return;
         }
         var _loc3_:IShootTargetHandler = this.handlerManager.getHandler(_loc2_);
         var _loc4_:Boolean = Boolean(_loc3_.validateHit(_loc2_));
         if((_loc4_) && this._isImmuneFromEffect)
         {
            return;
         }
         ShootClient.instance.sendHitValidateResult(_loc4_,_loc2_.targetType,_loc2_.key,this.getSubSocketClient());
      }
      
      private function onBump(param1:SocketClientEvent) : void
      {
         var _loc2_:ShootInfo = new ShootInfo();
         _loc2_.parse(param1.params.info);
         var _loc3_:Boolean = Boolean(param1.params.hit);
         var _loc4_:IShootTargetHandler = this.handlerManager.getHandler(_loc2_);
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:TargetInfo = _loc4_.targetInfo;
         this.bump(_loc2_,_loc3_,_loc5_);
      }
      
      private function bump(param1:ShootInfo, param2:Boolean, param3:TargetInfo) : void
      {
         var onPlayed:Function = null;
         var shootInfo:ShootInfo = param1;
         var hit:Boolean = param2;
         var targetInfo:TargetInfo = param3;
         onPlayed = function():void
         {
            this.dispatchEvent(new ShootServiceEvent(ShootServiceEvent.onBump,{
               "hit":hit,
               "targetInfo":targetInfo,
               "shootInfo":shootInfo
            }));
         };
         var onGetEffectService:Function = function(param1:IShootEffectService, param2:Object):void
         {
            var _loc3_:IShootEffectTarget = null;
            var _loc4_:IShootTargetHandler = this.handlerManager.getHandler(shootInfo);
            if(_loc4_ == null)
            {
               return;
            }
            _loc3_ = _loc4_.onBump(shootInfo,hit);
            param1.shoot(shootInfo.from,shootInfo.cardId,_loc3_,shootInfo,onPlayed,this);
         };
         ServiceContainer.instance.tryGetService(IShootEffectService,onGetEffectService,this);
      }
      
      private function onUserVariablesUpdate(param1:SocketClientEvent) : void
      {
         var changedVars:Array;
         var value:String;
         var values:Array;
         var effectes:String;
         var removeEffectes:String;
         var targetName:String = null;
         var addEffect:String = null;
         var effect:String = null;
         var arEffectes:Array = null;
         var arRemoveEffectes:Array = null;
         var timer:Timer = null;
         var thisObject:ShootService = null;
         var evt:SocketClientEvent = param1;
         var user:User = evt.params.user;
         if(!PlayerManager.getInstance().playeresVisible && user.getName() != UserInfo.userName)
         {
            return;
         }
         changedVars = evt.params.changedVars;
         if(!changedVars.hasOwnProperty(TargetEffectKey))
         {
            return;
         }
         value = user.getVariable(TargetEffectKey);
         values = value.split(";");
         targetName = values[0];
         effectes = values[1];
         addEffect = values[2];
         removeEffectes = values[3];
         if(this._isImmuneFromEffect && UserInfo.userName == user.getName())
         {
            return;
         }
         arEffectes = [];
         for each(effect in effectes.split(","))
         {
            arEffectes.push(new int(effect));
         }
         arRemoveEffectes = [];
         if(removeEffectes != "")
         {
            for each(effect in removeEffectes.split(","))
            {
               arRemoveEffectes.push(new int(effect));
            }
         }
         if(this.isNeedDelay)
         {
            timer = new Timer(1000,1);
            thisObject = this;
            timer.addEventListener(TimerEvent.TIMER,function(param1:TimerEvent):*
            {
               refreshPlayerEffect(targetName,arEffectes,addEffect,arRemoveEffectes);
               timer.stop();
            });
            timer.start();
         }
         else
         {
            this.refreshPlayerEffect(targetName,arEffectes,addEffect,arRemoveEffectes);
         }
      }
      
      private function refreshPlayerEffect(param1:String, param2:Array, param3:String, param4:Array) : void
      {
         var _loc5_:IShootTargetHandler = this.handlerManager.getPlayerHandler(param1);
         if(_loc5_ != null)
         {
            _loc5_.refreshEffect(param2,new int(param3),param4);
         }
      }
      
      private function onUserEnter(param1:PlayerManagerEvent) : void
      {
         var _loc2_:PlayerBase = param1.player;
         var _loc3_:String = _loc2_.getName();
         var _loc4_:User = SocketClient.instance.activeRoom.getUser(_loc3_);
         if(!PlayerManager.getInstance().playeresVisible && _loc3_ != UserInfo.userName)
         {
            return;
         }
         var _loc5_:* = _loc4_.getVariable(TargetEffectKey);
         if(_loc5_ == null || _loc5_ == undefined)
         {
            return;
         }
         this.showEffect(_loc5_);
      }
      
      private function showEffect(param1:String) : void
      {
         var _loc5_:String = null;
         var _loc7_:IShootTargetHandler = null;
         var _loc8_:int = 0;
         var _loc2_:Array = param1.split(";");
         var _loc3_:String = _loc2_[0];
         var _loc4_:String = _loc2_[1];
         var _loc6_:Array = [];
         for each(_loc5_ in _loc4_.split(","))
         {
            _loc6_.push(new int(_loc5_));
         }
         _loc7_ = this.handlerManager.getPlayerHandler(_loc3_);
         for each(_loc8_ in _loc6_)
         {
            _loc7_.refreshEffect(_loc6_,new int(_loc8_),[]);
         }
      }
      
      public function getMyCards() : Array
      {
         return this.getMyMaterials();
      }
      
      public function getCard(param1:int) : ShootCard
      {
         return this.getMaterialById(param1) as ShootCard;
      }
      
      public function getCardView(param1:int) : Sprite
      {
         var cotainer:ViewContainer = null;
         var cardId:int = param1;
         cotainer = ViewContainer.creatWaitingView(30,30);
         var onGetView:Function = function(param1:DisplayObject):*
         {
            cotainer.setView(param1);
            this.onGetView(cardId,cotainer);
         };
         var viewCreator:ShootCardViewCreator = new ShootCardViewCreator();
         var view:DisplayObject = viewCreator.getView(cardId,onGetView,this);
         if(view != null)
         {
            cotainer.setView(view);
         }
         return cotainer;
      }
      
      override public function getView(param1:int) : DisplayObject
      {
         var materialId:int = param1;
         var onGetView:Function = function(param1:DisplayObject):*
         {
            this.onGetView(materialId,param1);
         };
         var viewCreator:ShootCardViewCreator = new ShootCardViewCreator();
         return viewCreator.getView(materialId,onGetView,this);
      }
      
      public function getShootButton() : Sprite
      {
         return new ShootButtonWrap();
      }
      
      public function setReplaceEffectById(param1:int) : void
      {
         SocketClient.instance.addEventListener(ShootClient.setReplaceEffect,this.onSetReplaceEffect);
         ShootClient.instance.setReplaceEffectById(param1,this.getSubSocketClient());
         this.isNeedDelay = false;
      }
      
      public function cancelReplaceEffectById(param1:int) : void
      {
         ShootClient.instance.cancelReplaceEffectById(param1,this.getSubSocketClient());
      }
      
      private function onSetReplaceEffect(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(ShootClient.setReplaceEffect,this.onSetReplaceEffect);
         this.dispatchEvent(new ShootServiceEvent(ShootServiceEvent.onReplaceEffectComplete,param1.params));
      }
      
      public function setIsImmuneFromEffect(param1:Boolean) : void
      {
         this._isImmuneFromEffect = param1;
      }
      
      private function onUnloadScene(param1:SceneManagerEvent) : *
      {
         this.unReady();
      }
      
      public function cardFilter(param1:Array, param2:String = "该射击卡暂时不能使用！") : void
      {
         this.shootcardFilter = param1;
         this.filterNotice = param2;
      }
      
      public function getFilterArray() : Array
      {
         return this.shootcardFilter;
      }
      
      public function getFilterNotice() : String
      {
         return this.filterNotice;
      }
      
      public function removeCardFilter() : void
      {
         this.shootcardFilter = [];
         this.filterNotice = "";
      }
   }
}

