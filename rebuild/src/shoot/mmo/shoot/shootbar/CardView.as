package mmo.shoot.shootbar
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.shoot.data.ShootCard;
   import mmo.interfaces.shoot.data.UserShootCard;
   
   public class CardView extends MovieClip implements IDispose
   {
      
      public var selectMask:MovieClip;
      
      public var txtQuantity:TextField;
      
      private var _userShootCard:UserShootCard;
      
      private var cardView:Sprite;
      
      private var selectMaskPanel:Sprite;
      
      private var _skinSvr:NoSkins = NoSkins.instance;
      
      public function CardView()
      {
         super();
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
         this.mouseChildren = false;
         this.selectMaskPanel = this.getChildByName("selectMask") as Sprite;
         this.removeChild(this.selectMaskPanel);
         TextField(this.txtQuantity).text = "";
         this.addEventListener(MouseEvent.ROLL_OVER,this.onMouseOver);
         this.addEventListener(MouseEvent.ROLL_OUT,this.onMouseOut);
         CommonEventDispatcher.instance.addEventListener(NoSkins.CHANGE,this.onChangeSkin);
         this.addEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStage);
      }
      
      private function onChangeSkin(param1:CommonEvent) : void
      {
         this.clearCard();
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
         if(this._userShootCard != null)
         {
            this.showCard();
         }
      }
      
      public function set card(param1:UserShootCard) : void
      {
         this.clearCard();
         this._userShootCard = param1;
         if(this._userShootCard != null)
         {
            this.showCard();
         }
      }
      
      public function get card() : UserShootCard
      {
         return this._userShootCard;
      }
      
      private function clearCard() : void
      {
         if(this._userShootCard == null)
         {
            return;
         }
         this.buttonMode = false;
         this.removeChild(this.cardView);
         this.cardView = null;
         if(this.selectMaskPanel.parent != null)
         {
            this.removeChild(this.selectMaskPanel);
         }
         this._userShootCard = null;
         this.txtQuantity.text = "";
         TipsManager.getInstance().removeTips(this);
      }
      
      private function showCard() : void
      {
         this.buttonMode = true;
         var _loc1_:IShootService = ServiceContainer.getService(IShootService) as IShootService;
         this.cardView = _loc1_.getCardView(this._userShootCard.materialId);
         this.addChild(this.cardView);
         this.showCardInfo();
      }
      
      private function addTips() : void
      {
         if(this._userShootCard == null)
         {
            return;
         }
         var _loc1_:IShootService = ServiceContainer.getService(IShootService) as IShootService;
         var _loc2_:ShootCard = _loc1_.getCard(this._userShootCard.materialId);
         TipsManager.getInstance().addTips(this,_loc2_.name,100);
      }
      
      private function onMouseOver(param1:MouseEvent) : void
      {
         if(this.cardView == null)
         {
            return;
         }
         this.addChildAt(this.selectMaskPanel,this.getChildIndex(this.cardView) - 1);
      }
      
      private function onMouseOut(param1:MouseEvent) : void
      {
         if(this.selectMaskPanel.parent == null)
         {
            return;
         }
         this.removeChild(this.selectMaskPanel);
      }
      
      private function onAddToStage(param1:Event) : void
      {
         this.showCardInfo();
      }
      
      private function showCardInfo() : void
      {
         this.addTips();
         if(this._userShootCard != null && this._userShootCard.quantity > 1)
         {
            this.txtQuantity.text = this._userShootCard.quantity.toString();
         }
         else if(this.txtQuantity.parent != null)
         {
            this.removeChild(this.txtQuantity);
         }
         this.addChild(this.txtQuantity);
      }
      
      private function onRemoveFromStage(param1:Event) : void
      {
         if(this._userShootCard != null)
         {
            TipsManager.getInstance().removeTips(this);
         }
      }
      
      public function dispose() : void
      {
         this.removeEventListener(Event.ADDED_TO_STAGE,this.onAddToStage);
         this.removeEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveFromStage);
         this.clearCard();
         this.selectMaskPanel = null;
         this.removeEventListener(MouseEvent.ROLL_OVER,this.onMouseOver);
         this.removeEventListener(MouseEvent.ROLL_OUT,this.onMouseOut);
      }
   }
}

