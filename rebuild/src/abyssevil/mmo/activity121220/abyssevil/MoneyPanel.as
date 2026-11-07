package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.catalog.LoadBookEvent;
   import mmo.interfaces.catalog.LoadBookEventDispatcher;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMallBuyMaterialHelper;
   import mmo.loader.scheduler.ResScheduler;
   
   public class MoneyPanel extends Sprite implements IDispose, IShowPanel
   {
      
      private static const itemIds:Array = [636,637,638];
      
      public var btnclose:MovieClip;
      
      public var buy0:MovieClip;
      
      public var buy1:MovieClip;
      
      public var buy2:MovieClip;
      
      public var btnevo:SimpleButton;
      
      private var cb:Function;
      
      private var hasAll:Boolean;
      
      private var hasHave:Boolean;
      
      private var evoBtn:SimpleButton;
      
      private var btnbuy0:MovieClip;
      
      private var btnbuy1:MovieClip;
      
      private var btnbuy2:MovieClip;
      
      public function MoneyPanel(param1:Function)
      {
         super();
         this.cb = param1;
         this.evoBtn = getChildByName("btnevo") as SimpleButton;
         this.btnbuy0 = getChildByName("buy0") as MovieClip;
         this.btnbuy1 = getChildByName("buy1") as MovieClip;
         this.btnbuy2 = getChildByName("buy2") as MovieClip;
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         this.btnbuy0.removeEventListener(MouseEvent.CLICK,this.onBuy0);
         this.btnbuy1.removeEventListener(MouseEvent.CLICK,this.onBuy1);
         this.btnbuy2.removeEventListener(MouseEvent.CLICK,this.onBuy2);
      }
      
      private function onBuy0(param1:MouseEvent) : void
      {
         if(!this.btnbuy0.enabled)
         {
            return;
         }
         this.toBuy(itemIds[0]);
      }
      
      private function onBuy1(param1:MouseEvent) : void
      {
         if(!this.btnbuy1.enabled)
         {
            return;
         }
         this.toBuy(itemIds[1]);
      }
      
      private function onBuy2(param1:MouseEvent) : void
      {
         if(!this.btnbuy2.enabled)
         {
            return;
         }
         this.toBuy(itemIds[2]);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = DisplayObject(param1.target).name;
         if(_loc2_ == "btnclose")
         {
            this.cancel();
         }
      }
      
      private function toBuy(param1:int) : void
      {
         var itemId:int = param1;
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(IRmbShoppingMallBuyMaterialHelper,function(param1:IRmbShoppingMallBuyMaterialHelper, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.buyMaterialById(itemId,MaterialTypes.ITEM,1,"182");
         });
      }
      
      private function onClosebook(param1:LoadBookEvent) : void
      {
         LoadBookEventDispatcher.instence.removeEventListener(LoadBookEvent.ON_CLOSE,this.onClosebook);
         var _loc2_:String = param1.params.no as String;
         if(_loc2_ == "catalog201005")
         {
            this.updatePanel();
         }
      }
      
      private function cancel() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      public function showPanel() : void
      {
         SundriesClient.logOpen("182");
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.evoBtn.addEventListener(MouseEvent.CLICK,this.onClickEvo);
         this.btnbuy0.addEventListener(MouseEvent.CLICK,this.onBuy0);
         this.btnbuy1.addEventListener(MouseEvent.CLICK,this.onBuy1);
         this.btnbuy2.addEventListener(MouseEvent.CLICK,this.onBuy2);
         this.updatePanel();
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      private function onClickEvo(param1:MouseEvent) : void
      {
         if(!this.evoBtn.enabled)
         {
            return;
         }
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener("57_8",this.onEvo);
         SocketClient.instance.sendXtMessage("SynthesizeExtension","57_8",{
            "id":344,
            "num":1
         });
      }
      
      private function onEvo(param1:SocketClientEvent) : void
      {
         var res:int;
         var e:SocketClientEvent = param1;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener("57_8",this.onEvo);
         res = e.params.res as int;
         if(res == 1)
         {
            this.updatePanel();
            ProgressFullSprite.show();
            ResScheduler.getResource("activityres/activity121220/abyssevilbuymovie",function(param1:MovieClip):void
            {
               var c:MovieClip = param1;
               ProgressFullSprite.close();
               c.addFrameScript(c.totalFrames - 1,function():void
               {
                  ModalDialogManager.getInstance().removeModalDialog(c);
                  c.stop();
                  cancel();
                  var _loc1_:IMaterialGetPanel = ServiceContainer.instance.getService(IMaterialGetPanel) as IMaterialGetPanel;
                  _loc1_.showPanel(MaterialTypes.PET_EGG,1348,1);
               });
               ModalDialogManager.getInstance().addModalDialogWithChangLayer(c,AlignType.NONE);
               c.gotoAndPlay(1);
            },"mmo.activity121220.abyssevil.BuyMovie");
         }
         else
         {
            NewDialog.showFailMessage("召唤失败！");
         }
      }
      
      public function updatePanel() : void
      {
         var _loc2_:UserItem = null;
         var _loc4_:MovieClip = null;
         var _loc1_:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         this.hasAll = true;
         this.hasHave = false;
         var _loc3_:int = 0;
         while(_loc3_ < itemIds.length)
         {
            _loc2_ = _loc1_.getMyItemById(itemIds[_loc3_]);
            if(_loc2_ == null)
            {
               this.hasAll = false;
               break;
            }
            if(_loc2_ != null && _loc2_.quantity == 0)
            {
               this.hasHave = true;
               break;
            }
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < itemIds.length)
         {
            _loc2_ = _loc1_.getMyItemById(itemIds[_loc3_]);
            _loc4_ = getChildByName("buy" + _loc3_) as MovieClip;
            if(_loc2_ == null)
            {
               _loc4_.filters = null;
               _loc4_.enabled = true;
               _loc4_.gotoAndStop(1);
            }
            else
            {
               _loc4_.filters = null;
               _loc4_.enabled = false;
               _loc4_.gotoAndStop(2);
            }
            _loc3_++;
         }
         TipsManager.getInstance().removeTips(this.evoBtn);
         if(this.hasHave)
         {
            DisplayUtil.applyGray(this.evoBtn);
            this.evoBtn.enabled = false;
            TipsManager.getInstance().addTips(this.evoBtn,"依靠星币的力量只能获得一只魔龙王哦！");
         }
         else if(this.hasAll)
         {
            this.evoBtn.filters = null;
            this.evoBtn.enabled = true;
         }
         else
         {
            DisplayUtil.applyGray(this.evoBtn);
            this.evoBtn.enabled = false;
            TipsManager.getInstance().addTips(this.evoBtn,"只有集齐三块魂石才能召唤出魔龙王哦！");
         }
      }
   }
}

