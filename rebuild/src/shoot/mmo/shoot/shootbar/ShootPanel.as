package mmo.shoot.shootbar
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.changeable.ChangeableCollectionEvent;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.data.UserShootCard;
   import mmo.shoot.data.CardData;
   
   public class ShootPanel extends MovieClip implements IDispose
   {
      
      public var mclock:MovieClip;
      
      public var pgManager:PageManager;
      
      public var view0:CardView;
      
      public var view1:CardView;
      
      public var view2:CardView;
      
      public var view3:CardView;
      
      public var view4:CardView;
      
      public var view5:CardView;
      
      public var view6:CardView;
      
      public var view7:CardView;
      
      public var view8:CardView;
      
      public var view9:CardView;
      
      private var itemService:IItemService;
      
      private var shootService:IShootService;
      
      private var views:Array = [];
      
      private var isFirstShow:Boolean = true;
      
      private var pageManager:PageManagerBase;
      
      private var _skinSvr:NoSkins = NoSkins.instance;
      
      private const sortCards:Array = [1,2,100,101];
      
      private var mcLock:MovieClip;
      
      public function ShootPanel()
      {
         var _loc2_:CardView = null;
         super();
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
         var _loc1_:int = 0;
         while(_loc1_ < 10)
         {
            _loc2_ = this.getChildByName("view" + _loc1_) as CardView;
            this.views.push(_loc2_);
            _loc2_.addEventListener(MouseEvent.CLICK,this.onViewClick);
            _loc1_++;
         }
         this.itemService = ServiceContainer.getService(IItemService) as IItemService;
         this.pageManager = this.getChildByName("pgManager") as PageManagerBase;
         this.pageManager.addEventListener(PageManagerBase.onPageChanged,this.onPageChanged);
         this.shootService = ServiceContainer.getService(IShootService) as IShootService;
         this.shootService.addEventListener(ChangeableCollectionEvent.onAddObject,this.onAddShootCard);
         this.shootService.addEventListener(ChangeableCollectionEvent.onObjectPropertyChanged,this.onChangeShootCard);
         this.shootService.addEventListener(ChangeableCollectionEvent.onRemoveObject,this.onRemoveShootCard);
         CommonEventDispatcher.instance.addEventListener(NoSkins.CHANGE,this.onChangeSkin);
         this.mcLock = getChildByName("mclock") as MovieClip;
         this.mcLock.addEventListener(MouseEvent.CLICK,this.onClickLock);
         this.mcLock.gotoAndStop(1);
         this.updateLockTips();
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
      }
      
      private function onChangeSkin(param1:CommonEvent) : void
      {
         this.mcLock.removeEventListener(MouseEvent.CLICK,this.onClickLock);
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
         this.mcLock = getChildByName("mclock") as MovieClip;
         this.mcLock.addEventListener(MouseEvent.CLICK,this.onClickLock);
         this.mcLock.gotoAndStop(1);
         this.updateLockTips();
      }
      
      private function onAddToStage(param1:Event) : void
      {
         this.updateLockTips();
      }
      
      private function updateLockTips() : void
      {
         if(this.mcLock.currentFrame == 1)
         {
            TipsManager.getInstance().addTips(this.mcLock,"点击这里可以锁定这个界面哦！");
         }
         else
         {
            TipsManager.getInstance().removeTips(this.mcLock);
         }
      }
      
      private function onClickLock(param1:MouseEvent) : void
      {
         if(this.mcLock.currentFrame == 1)
         {
            this.mcLock.gotoAndStop(2);
         }
         else
         {
            this.mcLock.gotoAndStop(1);
         }
         this.updateLockTips();
      }
      
      public function isLock() : Boolean
      {
         if(this.mcLock.currentFrame == 1)
         {
            return false;
         }
         return true;
      }
      
      private function onViewClick(param1:MouseEvent) : void
      {
         var _loc4_:* = undefined;
         var _loc2_:CardView = param1.target as CardView;
         if(_loc2_.card == null)
         {
            return;
         }
         var _loc3_:Array = this.shootService.getFilterArray();
         if(_loc3_ == null || _loc3_.length == 0)
         {
            CommonEventDispatcher.instance.dispatchEvent(new Event("clickShootCard"));
            this.shootService.shootReady(_loc2_.card.materialId);
            if(!this.isLock())
            {
               this.parent.removeChild(this);
            }
            return;
         }
         for(_loc4_ in _loc3_)
         {
            if(_loc3_[_loc4_] == _loc2_.card.materialId)
            {
               CommonEventDispatcher.instance.dispatchEvent(new Event("clickShootCard"));
               this.shootService.shootReady(_loc2_.card.materialId);
               if(!this.isLock())
               {
                  this.parent.removeChild(this);
               }
               return;
            }
         }
         NewDialog.showSucceedMessage(this.shootService.getFilterNotice());
      }
      
      public function show() : void
      {
         var _loc1_:Array = this.getSortAndFiltCarts();
         this.pageManager.recordCount = _loc1_.length;
         this.pageManager.reset();
      }
      
      private function onPageChanged(param1:Event) : void
      {
         this.showCards();
      }
      
      private function showCards() : void
      {
         var _loc4_:CardView = null;
         var _loc5_:int = 0;
         var _loc6_:UserShootCard = null;
         var _loc1_:Array = this.getSortAndFiltCarts();
         var _loc2_:int = int(_loc1_.length);
         this.pageManager.recordCount = _loc1_.length;
         var _loc3_:int = 0;
         while(_loc3_ < this.views.length)
         {
            _loc4_ = this.views[_loc3_] as CardView;
            _loc5_ = this.pageManager.pageIndex * this.views.length + _loc3_;
            _loc6_ = UserShootCard(_loc1_[_loc5_]);
            if(_loc5_ >= _loc2_)
            {
               _loc4_.card = null;
            }
            else
            {
               _loc4_.card = _loc6_;
            }
            _loc3_++;
         }
      }
      
      private function getSortAndFiltCarts() : Array
      {
         var onSortFun:Function;
         var userCard:UserShootCard = null;
         var cards:Array = this.shootService.getMyMaterials();
         var tempArr:Array = [];
         var i:int = 0;
         while(i < cards.length)
         {
            userCard = UserShootCard(cards[i]);
            if(CardData.hideCards.indexOf(userCard.materialId) == -1)
            {
               tempArr.push(userCard);
            }
            i++;
         }
         onSortFun = function(param1:UserShootCard, param2:UserShootCard):int
         {
            var _loc3_:int = int(param1.materialId);
            var _loc4_:int = int(param2.materialId);
            var _loc5_:int = sortCards.indexOf(_loc3_);
            var _loc6_:int = sortCards.indexOf(_loc4_);
            if(_loc5_ != -1)
            {
               if(_loc6_ != -1)
               {
                  return _loc5_ - _loc6_;
               }
               return -1;
            }
            if(_loc6_ != -1)
            {
               return 1;
            }
            return _loc4_ - _loc3_;
         };
         tempArr.sort(onSortFun);
         return tempArr;
      }
      
      private function onAddShootCard(param1:ChangeableCollectionEvent) : void
      {
         if(this.pageManager.pageCount == 0 || this.pageManager.pageIndex == this.pageManager.pageCount - 1)
         {
            this.showCards();
         }
      }
      
      private function onChangeShootCard(param1:ChangeableCollectionEvent) : void
      {
         this.showCards();
      }
      
      private function onRemoveShootCard(param1:ChangeableCollectionEvent) : void
      {
         this.showCards();
      }
      
      public function dispose() : void
      {
         var _loc1_:CardView = null;
         this.pageManager.removeEventListener(PageManagerBase.onPageChanged,this.onPageChanged);
         this.pageManager = null;
         this.shootService.removeEventListener(ChangeableCollectionEvent.onAddObject,this.onAddShootCard);
         this.shootService.removeEventListener(ChangeableCollectionEvent.onObjectPropertyChanged,this.onChangeShootCard);
         this.shootService.removeEventListener(ChangeableCollectionEvent.onRemoveObject,this.onRemoveShootCard);
         this.shootService = null;
         this.itemService = null;
         for each(_loc1_ in this.views)
         {
            _loc1_.dispose();
         }
         this.views = null;
         this.mcLock.removeEventListener(MouseEvent.CLICK,this.onClickLock);
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
      }
   }
}

