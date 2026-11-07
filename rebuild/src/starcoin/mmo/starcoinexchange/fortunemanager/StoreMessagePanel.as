package mmo.starcoinexchange.fortunemanager
{
   import mmo.revival.starcoin.Beans;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DateUtil;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManager;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManagerClient;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   
   public class StoreMessagePanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var canstore0:MovieClip;
      
      public var canstore1:MovieClip;
      
      public var canstore2:MovieClip;
      
      public var canstore3:MovieClip;
      
      public var canstore4:MovieClip;
      
      public var showBtn0:MovieClip;
      
      public var showBtn1:MovieClip;
      
      public var showBtn2:MovieClip;
      
      public var showBtn3:MovieClip;
      
      public var showBtn4:MovieClip;
      
      public var storeMessage0:MovieClip;
      
      public var storeMessage1:MovieClip;
      
      public var storeMessage2:MovieClip;
      
      public var storeMessage3:MovieClip;
      
      public var storeMessage4:MovieClip;
      
      private var currentClickIndex:int = -1;
      
      public function StoreMessagePanel()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function initPanel(param1:Object) : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         var _loc8_:Date = null;
         var _loc9_:Date = null;
         if(FortuneManager.getInstance().checkForEmptyStore())
         {
            this.handNoStoreMessage();
            return;
         }
         var _loc2_:Array = FortuneManager.getInstance().myStoreFortune;
         var _loc3_:int = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc4_ = MovieClip(this.getChildByName("showBtn" + _loc3_));
            if(_loc4_ == null)
            {
               break;
            }
            _loc4_.gotoAndStop(1);
            _loc5_ = MovieClip(this.getChildByName("storeMessage" + _loc3_.toString()));
            _loc6_ = MovieClip(_loc4_.getChildByName("storeBtn" + _loc3_));
            _loc6_.mouseChildren = false;
            _loc6_.buttonMode = true;
            MovieClip(this.getChildByName("canstore" + _loc3_)).visible = false;
            if(_loc2_[_loc3_] != null)
            {
               _loc5_.visible = true;
               _loc7_ = int(_loc2_[_loc3_].money);
               _loc8_ = _loc2_[_loc3_].storeDate;
               _loc9_ = _loc2_[_loc3_].endDate;
               TextField(_loc5_.getChildByName("money")).text = _loc7_.toString();
               TextField(_loc5_.getChildByName("storeDate")).text = _loc8_.fullYear + "年" + (_loc8_.month + 1) + "月" + _loc8_.date + "日";
               TextField(_loc5_.getChildByName("endDate")).text = _loc9_.fullYear + "年" + (_loc9_.month + 1) + "月" + _loc9_.date + "日";
               _loc6_.gotoAndStop(2);
               _loc6_.removeEventListener(MouseEvent.CLICK,this.onClickStoreBtn);
               _loc6_.addEventListener(MouseEvent.CLICK,this.onClickGetBtn);
            }
            else
            {
               _loc5_.visible = false;
               _loc6_.gotoAndStop(1);
               _loc6_.removeEventListener(MouseEvent.CLICK,this.onClickGetBtn);
               _loc6_.addEventListener(MouseEvent.CLICK,this.onClickStoreBtn);
            }
            _loc3_++;
         }
      }
      
      private function handNoStoreMessage() : void
      {
         var _loc4_:MovieClip = null;
         MovieClip(this.getChildByName("canstore0")).visible = true;
         MovieClip(this.getChildByName("storeMessage0")).visible = false;
         var _loc1_:* = this.getChildByName("showBtn0") as MovieClip;
         var _loc2_:MovieClip = MovieClip(_loc1_.getChildByName("storeBtn0"));
         _loc2_.gotoAndStop(1);
         _loc2_.mouseChildren = false;
         _loc2_.buttonMode = true;
         _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickGetBtn);
         _loc2_.addEventListener(MouseEvent.CLICK,this.onClickStoreBtn);
         var _loc3_:int = 1;
         while(_loc3_ < 5)
         {
            _loc4_ = this.getChildByName("showBtn" + _loc3_) as MovieClip;
            _loc4_.gotoAndStop(2);
            MovieClip(this.getChildByName("canstore" + _loc3_)).visible = false;
            MovieClip(this.getChildByName("storeMessage" + _loc3_)).visible = false;
            _loc3_++;
         }
      }
      
      private function onClickGetBtn(param1:MouseEvent) : void
      {
         var _loc5_:int = 0;
         var _loc6_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:Date = null;
         var _loc9_:Date = null;
         var _loc10_:int = 0;
         var _loc11_:Date = null;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc2_:DisplayObject = param1.target as DisplayObject;
         var _loc3_:String = _loc2_.name;
         var _loc4_:String = "storeBtn";
         if(_loc3_.indexOf(_loc4_) != -1)
         {
            _loc5_ = parseInt(_loc3_.slice(_loc4_.length));
            this.currentClickIndex = _loc5_;
            _loc6_ = FortuneManager.getInstance().myStoreFortune;
            _loc7_ = int(_loc6_[_loc5_].money);
            _loc8_ = _loc6_[_loc5_].storeDate;
            _loc9_ = _loc6_[_loc5_].endDate;
            _loc10_ = int(_loc6_[_loc5_].day);
            _loc11_ = DateUtil.getServerTime();
            if(this.dateMinus(_loc11_,_loc9_) > 0)
            {
               SocketClient.instance.addEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayMoney);
               FortuneManagerClient.getInstance().takeAwayAccount(_loc5_);
               return;
            }
            if(this.dateMinus(_loc11_,_loc8_) > 24 * 60 * 60 * 1000)
            {
               _loc12_ = Math.floor(this.dateMinus(_loc11_,_loc8_) / (24 * 60 * 60 * 1000));
               _loc13_ = Math.ceil(this.dateMinus(_loc9_,_loc11_) / (24 * 60 * 60 * 1000));
               FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{
                  "panelId":PanelType.advanceGetBackPanel,
                  "money":_loc7_,
                  "accrual":_loc7_ * _loc12_ * 0.001,
                  "day":_loc13_,
                  "id":_loc5_
               }));
            }
            else
            {
               FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{
                  "panelId":PanelType.oneDayGetBackPanel,
                  "id":_loc5_,
                  "money":_loc7_
               }));
            }
            return;
         }
      }
      
      private function onTakeAwayMoney(param1:SocketClientEvent) : void
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdTakeAwayAccount,this.onTakeAwayMoney);
         Beans.update(param1.params);
         if(param1.params.res != -1)
         {
            if(this.currentClickIndex == -1)
            {
               return;
            }
            _loc2_ = FortuneManager.getInstance().myStoreFortune;
            _loc3_ = int(_loc2_[this.currentClickIndex].money);
            FortuneManager.getInstance().returnMyStore(this.currentClickIndex);
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{
               "panelId":PanelType.returnCoinPanel,
               "money":_loc3_,
               "accrual":param1.params.res
            }));
         }
      }
      
      private function onClickStoreBtn(param1:MouseEvent) : void
      {
         var _loc5_:int = 0;
         var _loc2_:DisplayObject = param1.target as DisplayObject;
         var _loc3_:String = _loc2_.name;
         var _loc4_:String = "storeBtn";
         if(_loc3_.indexOf(_loc4_) != -1)
         {
            _loc5_ = parseInt(_loc3_.slice(_loc4_.length));
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{
               "panelId":PanelType.storeCoinPanel,
               "id":_loc5_
            }));
         }
      }
      
      private function dateMinus(param1:Date, param2:Date) : Number
      {
         return param1.getTime() - param2.getTime();
      }
   }
}

