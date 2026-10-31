package mmo.game.parkour.panel
{
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.material.MaterialResultDialogHelper;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourConfig;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.play.activity.handler.money.MyXingBiHandler;
   
   public class ParkourBuyMoneyPanel extends ParkourPanelBase
   {
      
      private static const BuyServices:Array = [2728,2730,2732,2734];
      
      private static const MemberBuyServices:Array = [2729,2731,2733,2735];
      
      private static const BuyNumOfMoneys:Array = [2500,5200,11000,24000];
      
      private static const PreNameOfBtnBuy:String = "btnBuy_";
      
      private var xingBiHandler:MyXingBiHandler;
      
      private var buyingId:int;
      
      public function ParkourBuyMoneyPanel()
      {
         super(ParkourResConfig.BuyMoneyPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.xingBiHandler = new MyXingBiHandler(panel,"txtMyXingbi");
         SundriesClient.logOpen(ParkourConfig.LogBuy);
         this.refresh();
         showThisPanel();
      }
      
      private function refresh() : void
      {
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         var id:int = 0;
         var onOk:Function = null;
         var targetName:String = param1;
         if(targetName == "btnBlue")
         {
            ParkourHelper.showOpenBluePage();
         }
         else if(targetName.indexOf(PreNameOfBtnBuy) != -1)
         {
            id = parseInt(targetName.substr(PreNameOfBtnBuy.length));
            onOk = function():void
            {
               buyMoney(id);
            };
            new ParkourBuyMoneyConfirmPanel(id,onOk).showPanel();
         }
      }
      
      private function buyMoney(param1:int) : void
      {
         this.buyingId = param1;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdBuyMoney,this.onCmdBuyMoney);
         ParkourClient.buyMoney(param1);
      }
      
      private function onCmdBuyMoney(param1:SocketClientEvent) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdBuyMoney,this.onCmdBuyMoney);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            _loc3_ = ParkourHelper.isMember() ? MemberBuyServices : BuyServices;
            _loc4_ = int(_loc3_[this.buyingId]);
            SundriesClient.logBuy(ParkourConfig.LogBuy,0,[[1,50,_loc4_]]);
            _loc5_ = int(BuyNumOfMoneys[this.buyingId]);
            ParkourUserData.instance.myMoney += _loc5_;
            NewDialog.showSucceedMessage("购买成功！恭喜你获得了" + _loc5_ + "金币!");
         }
         else
         {
            MaterialResultDialogHelper.showMaterialResultDialog(_loc2_,true);
         }
      }
      
      override protected function onDispose() : void
      {
         this.xingBiHandler.dispose();
      }
   }
}

