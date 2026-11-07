package mmo.activity130221.wolfandnightking
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.dialog.SpecialMessageDialog;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.material.MaterialClient;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.UserItem;
   import mmo.loader.scheduler.ResScheduler;
   
   public class WNKingStarPanel extends WNKingPanelBase
   {
      
      private var index:int;
      
      private var callBack:Function;
      
      private var panel:Sprite;
      
      public function WNKingStarPanel(param1:int, param2:Function = null)
      {
         super();
         this.index = param1;
         this.callBack = param2;
         this.initPanel();
      }
      
      private function initPanel() : void
      {
         var obj:Object = WNKingConfig.challengeStarArr[this.index];
         ResScheduler.getTempResource(obj.pathName,function(param1:Sprite, param2:Object = null):void
         {
            panel = param1;
            addChild(panel);
            updateItemState();
         },obj.className);
      }
      
      private function updateItemState() : void
      {
         var _loc4_:SimpleButton = null;
         var _loc5_:Sprite = null;
         var _loc6_:int = 0;
         var _loc7_:UserItem = null;
         var _loc1_:Array = WNKingConfig.challengeItemIdArr[this.index];
         var _loc2_:IItemService = ServiceContainer.getService(IItemService) as IItemService;
         var _loc3_:int = 0;
         while(_loc3_ < _loc1_.length)
         {
            _loc4_ = this.panel.getChildByName("btnBuy" + _loc3_.toString()) as SimpleButton;
            _loc5_ = this.panel.getChildByName("spGet" + _loc3_.toString()) as Sprite;
            _loc6_ = int(_loc1_[_loc3_]);
            _loc7_ = _loc2_.getMyItemById(_loc6_);
            if(_loc7_ == null || _loc7_.quantity == 0)
            {
               _loc5_.visible = false;
            }
            else
            {
               _loc4_.visible = false;
               _loc5_.visible = true;
            }
            _loc3_++;
         }
      }
      
      override protected function clickBtn(param1:MouseEvent) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = param1.target.name as String;
         if(_loc2_ == "btnClose")
         {
            this.closePanel();
         }
         else if(_loc2_.indexOf("btnBuy") != -1)
         {
            _loc3_ = parseInt(_loc2_.substr(6));
            this.tryBuy(_loc3_);
         }
      }
      
      private function tryBuy(param1:int) : void
      {
         var id:int = param1;
         var callBack:Function = function():void
         {
            confirmBuy(id);
         };
         new WNKingBuyConfirmPanel(this.index,id + 1,callBack).showPanel();
      }
      
      private function confirmBuy(param1:int) : void
      {
         var itemIdArr:Array;
         var itemId:int = 0;
         var id:int = param1;
         var priceArr:Array = WNKingConfig.itemPriceArr[this.index];
         var price:int = int(priceArr[id]);
         if(UserInfo.xingbi < price)
         {
            SpecialMessageDialog.showSpecialMessageDialog("XingbeShortageHandler","很抱歉，你的星币余额不足，目前你拥有" + UserInfo.xingbi + "星币。");
            return;
         }
         itemIdArr = WNKingConfig.challengeItemIdArr[this.index];
         itemId = int(itemIdArr[id]);
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(MaterialClient.cmdBuyMaterial,function onBuy(param1:SocketClientEvent):void
         {
            var _loc3_:IMaterialGetPanel = null;
            ProgressFullSprite.close();
            SocketClient.instance.removeEventListener(MaterialClient.cmdBuyMaterial,onBuy);
            var _loc2_:int = int(param1.params.result);
            switch(_loc2_)
            {
               case 1:
                  SundriesClient.logBuy(WNKingConfig.challengeLogArr[index],0,[[1,MaterialTypes.ITEM,itemId]]);
                  _loc3_ = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
                  _loc3_.showPanel(MaterialTypes.ITEM,itemId,1);
                  updateItemState();
                  break;
               case 101:
                  SpecialMessageDialog.showSpecialMessageDialog("XingbeShortageHandler","很抱歉，你的星币余额不足，目前你拥有" + UserInfo.xingbi + "星币。");
                  break;
               case 3:
                  NewDialog.showFailMessage("你不能拥有更多的该物品。");
                  break;
               case 12:
                  NewDialog.showFailMessage("已经到达当天消费上限，请明天再来吧!");
                  break;
               case 13:
                  NewDialog.showFailMessage("已经到达当月消费上限。");
                  break;
               default:
                  NewDialog.showFailMessage("购买失败，请联系客服。" + _loc2_);
            }
         });
         MaterialClient.getInstance().buyMaterial(MaterialTypes.ITEM,itemId,1,false);
      }
      
      override public function dispose() : void
      {
         super.dispose();
         if(this.callBack != null)
         {
            this.callBack.apply();
         }
      }
   }
}

