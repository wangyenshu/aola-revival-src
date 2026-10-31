package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.bonus.ShowBonusHelper;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.page.ParkourPageComponent;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourRewardInfo;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.helper.ParkourHelper;
   import mmo.game.parkour.panel.ui.ParkourRewardBox;
   import mmo.util.component.page.PageComponentEvent;
   
   public class ParkourRewardPanel extends ParkourPanelBase
   {
      
      private static const NumPerPage:int = 8;
      
      private static const PreNameOfmcBox:String = "mcBox_";
      
      private var pageComponent:ParkourPageComponent;
      
      private var boxs:Array = [];
      
      private var gettingRewardInfo:ParkourRewardInfo;
      
      public function ParkourRewardPanel()
      {
         super(ParkourResConfig.RewardPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.initBoxs();
         this.pageComponent = new ParkourPageComponent([],NumPerPage,panel.btnPrev,panel.btnNext,panel.txtPage);
         this.pageComponent.addEventListener(PageComponentEvent.ON_PAGE_CHANGE,this.onPageUpdate);
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdCheckReward,this.onCmdCheckReward);
         ParkourClient.checkReward();
      }
      
      private function onCmdCheckReward(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdCheckReward,this.onCmdCheckReward);
         this.pageComponent.updateData(ParkourHelper.parseRewardInfos(param1.params.gbs));
         this.refresh();
         showThisPanel();
      }
      
      private function initBoxs() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:ParkourRewardBox = null;
         var _loc1_:int = 0;
         while(_loc1_ < NumPerPage)
         {
            _loc2_ = panel.getChildByName(PreNameOfmcBox + _loc1_) as MovieClip;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickBox);
            _loc3_ = new ParkourRewardBox(_loc2_);
            this.boxs.push(_loc3_);
            _loc1_++;
         }
      }
      
      private function onPageUpdate(param1:Event) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc4_:ParkourRewardBox = null;
         var _loc5_:ParkourRewardInfo = null;
         var _loc1_:Array = this.pageComponent.getCurrentPageData();
         var _loc2_:int = 0;
         while(_loc2_ < this.boxs.length)
         {
            _loc4_ = this.boxs[_loc2_] as ParkourRewardBox;
            _loc5_ = _loc1_[_loc2_] as ParkourRewardInfo;
            _loc4_.showReward(_loc5_);
            _loc2_++;
         }
         var _loc3_:MovieClip = panel.getChildByName("mcNoReward") as MovieClip;
         _loc3_.visible = this.pageComponent.totalDataCount == 0;
      }
      
      private function onClickBox(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.currentTarget.name;
         var _loc3_:int = parseInt(_loc2_.substr(PreNameOfmcBox.length));
         var _loc4_:ParkourRewardBox = this.boxs[_loc3_] as ParkourRewardBox;
         if(_loc4_.getInfo() != null)
         {
            this.openBox(_loc4_.getInfo());
         }
      }
      
      private function openBox(param1:ParkourRewardInfo) : void
      {
         this.gettingRewardInfo = param1;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdGetReward,this.onCmdGetReward);
         ParkourClient.getReward(param1.id);
      }
      
      private function onCmdGetReward(param1:SocketClientEvent) : void
      {
         var bn:Array;
         var onShowBn:Function;
         var gBn:Array = null;
         var evt:SocketClientEvent = param1;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdGetReward,this.onCmdGetReward);
         gBn = evt.params.gBn;
         bn = evt.params.bn;
         onShowBn = function():void
         {
            ParkourHelper.showGBn(gBn);
         };
         --ParkourUserData.instance.rewardNum;
         ShowBonusHelper.showBonus(bn,onShowBn);
         this.pageComponent.deleteData(this.gettingRewardInfo);
         this.refresh();
      }
      
      override protected function onDispose() : void
      {
         var _loc2_:ParkourRewardBox = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.boxs.length)
         {
            _loc2_ = this.boxs[_loc1_] as ParkourRewardBox;
            _loc2_.dispose();
            _loc1_++;
         }
         this.pageComponent.destroy();
         this.pageComponent.disposeComponent();
      }
   }
}

