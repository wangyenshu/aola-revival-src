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
   
   public class ParkourBuyLovePanel extends ParkourPanelBase
   {
      
      private static const BuyServices:Array = [2736,2738,2740,2742];
      
      private static const MemberBuyServices:Array = [2737,2739,2741,2743];
      
      private static const BuyNumOfLoves:Array = [10,20,50,100];
      
      private static const PreNameOfBtnBuy:String = "btnBuy_";
      
      private var xingBiHandler:MyXingBiHandler;
      
      private var buyingId:int;
      
      public function ParkourBuyLovePanel()
      {
         super(ParkourResConfig.BuyLovePanel);
      }
      
      override protected function onShowPanel() : void
      {
         SundriesClient.logOpen(ParkourConfig.LogBuy);
         this.xingBiHandler = new MyXingBiHandler(panel,"txtMyXingbi");
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
            new ParkourBuyLoveConfirmPanel(id,onOk).showPanel();
         }
      }
      
      private function buyMoney(param1:int) : void
      {
         this.buyingId = param1;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdBuyLove,this.onCmdBuyLove);
         ParkourClient.buyLove(param1);
      }
      
      private function onCmdBuyLove(param1:SocketClientEvent) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdBuyLove,this.onCmdBuyLove);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            _loc3_ = ParkourHelper.isMember() ? MemberBuyServices : BuyServices;
            _loc4_ = int(_loc3_[this.buyingId]);
            SundriesClient.logBuy(ParkourConfig.LogBuy,0,[[1,50,_loc4_]]);
            _loc5_ = int(BuyNumOfLoves[this.buyingId]);
            ParkourUserData.instance.myLove += _loc5_;
            NewDialog.showSucceedMessage("购买成功！恭喜你获得了" + _loc5_ + "星星能量!");
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

