package mmo.starcoinexchange.fortunemanager
{
   import fl.controls.ComboBox;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;
   import mmo.common.DateUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.revival.starcoin.Beans;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEvent;
   import mmo.starcoinexchange.fortunemanager.event.FortuneManagerEventDispatcher;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManager;
   import mmo.starcoinexchange.fortunemanager.operate.FortuneManagerClient;
   import mmo.starcoinexchange.fortunemanager.operate.PanelType;
   import mmo.ui.skin.UISkin;
   
   public class StoreCoinPanel extends Sprite implements IFortuneManagerPanel
   {
      
      public var btnReturn:SimpleButton;
      
      public var btnSure:SimpleButton;
      
      public var mcStore:MovieClip;
      
      public var money:TextField;
      
      public var score:TextField;
      
      public var totalMoney:TextField;
      
      private var storeId:int;
      
      private var day:int = 1;
      
      private var comboBox:ComboBox;
      
      private var moneyTextField:TextField;
      
      private var isClicking:Boolean = false;
      
      public function StoreCoinPanel()
      {
         super();
         this.init();
         this.initListener();
      }
      
      private function init() : void
      {
         this.comboBox = new ComboBox();
         var _loc1_:TextFormat = new TextFormat("宋体",12,26367,false,false,false,"","",TextFormatAlign.LEFT,0,0,0,0);
         this.comboBox.textField.setStyle("textFormat",_loc1_);
         this.comboBox.dropdown.setRendererStyle("textFormat",_loc1_);
         this.comboBox.dropdown.height = 500;
         UISkin.displayCombox(this,this.mcStore,this.comboBox);
         this.comboBox.textField.setStyle("textFormat",_loc1_);
         this.comboBox.addItem({
            "label":"1",
            "data":1
         });
         var _loc2_:* = 0;
         while(_loc2_ < 6)
         {
            this.comboBox.addItem({
               "label":_loc2_ + 2,
               "data":_loc2_ + 2
            });
            _loc2_++;
         }
         this.moneyTextField = TextField(this.money);
         this.moneyTextField.restrict = "0-9";
      }
      
      private function initListener() : void
      {
         this.comboBox.addEventListener(Event.CHANGE,this.onDropListChange);
         this.moneyTextField.addEventListener(Event.CHANGE,this.onChangeMoney);
         SimpleButton(this.btnSure).addEventListener(MouseEvent.CLICK,this.onClickSure);
         SimpleButton(this.btnReturn).addEventListener(MouseEvent.CLICK,this.onClickClose);
      }
      
      private function onChangeMoney(param1:Event) : void
      {
         var _loc2_:String = this.moneyTextField.text;
         var _loc3_:int = parseInt(_loc2_);
         if(_loc3_ > Beans.count)
         {
            _loc3_ = int(Beans.count);
         }
         this.moneyTextField.text = _loc3_.toString();
         var _loc4_:int = int(_loc3_ * this.day / 35);
         TextField(this.totalMoney).text = _loc4_.toString();
      }
      
      private function onClickSure(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         if(this.isClicking)
         {
            return;
         }
         if(this.moneyTextField.text != null && this.moneyTextField.text != "")
         {
            _loc2_ = parseInt(this.moneyTextField.text);
            if(_loc2_ < 1000)
            {
               NewDialog.showFailMessage("要存入1000晶豆以上才行哦！");
               return;
            }
            if(_loc2_ > Beans.count)
            {
               NewDialog.showFailMessage("你身上的晶豆不够哦！");
               return;
            }
            if(_loc2_ > 5000)
            {
               NewDialog.showFailMessage("单笔存款不能超过5000晶豆哦！");
               return;
            }
            this.isClicking = true;
            SocketClient.instance.addEventListener(FortuneManagerClient.cmdDespositAccount,this.onDespositAccount);
            FortuneManagerClient.getInstance().despositAccount(this.storeId,_loc2_,this.day);
         }
         else
         {
            NewDialog.showFailMessage("你还没输入需要存入的晶豆数量哦！");
         }
      }
      
      private function onDespositAccount(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(FortuneManagerClient.cmdDespositAccount,this.onDespositAccount);
         this.isClicking = false;
         Beans.update(param1.params);
         if(param1.params.b)
         {
            FortuneManager.getInstance().storeFortuneOfMes(this.storeId,parseInt(this.moneyTextField.text),DateUtil.getServerTime(),this.day);
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{
               "panelId":PanelType.surePanel,
               "money":parseInt(this.moneyTextField.text),
               "day":this.day
            }));
         }
         else
         {
            NewDialog.showFailMessage("存款失败！");
            FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
         }
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         FortuneManagerEventDispatcher.getInstance().dispatchEvent(new FortuneManagerEvent(FortuneManagerEvent.SHOW_PANEL,{"panelId":PanelType.storeMessagePanel}));
      }
      
      private function onDropListChange(param1:Event) : void
      {
         this.day = this.comboBox.selectedItem.data;
         var _loc2_:String = this.moneyTextField.text;
         var _loc3_:int = parseInt(_loc2_);
         var _loc4_:int = int(_loc3_ * this.day / 35);
         TextField(this.totalMoney).text = _loc4_.toString();
      }
      
      public function initPanel(param1:Object) : void
      {
         this.storeId = param1.id;
         this.moneyTextField.text = "1000";
         TextField(this.totalMoney).text = "2";
         this.day = 1;
         this.comboBox.selectedItem = 1;
         TextField(this.score).text = Beans.count.toString();
      }
   }
}

