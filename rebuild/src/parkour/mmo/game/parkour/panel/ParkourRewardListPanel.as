package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.common.tab.ParkourTabComponent;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.panel.ui.ParkourRewardListUI;
   
   public class ParkourRewardListPanel extends ParkourPanelBase
   {
      
      private static const NumOfRewardList:int = 2;
      
      private var tabComponent:ParkourTabComponent;
      
      private var rewardListUIs:Array = [];
      
      public function ParkourRewardListPanel()
      {
         super(ParkourResConfig.RewardListPanel);
      }
      
      override protected function onShowPanel() : void
      {
         this.tabComponent = new ParkourTabComponent(panel,NumOfRewardList);
         this.initRewardListUIs();
         this.tabComponent.addEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
         this.tabComponent.showTab(0);
         this.refresh();
         showThisPanel();
      }
      
      private function initRewardListUIs() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < NumOfRewardList)
         {
            _loc2_ = panel.getChildByName("mcRewardList_" + _loc1_) as MovieClip;
            this.rewardListUIs.push(new ParkourRewardListUI(_loc2_));
            _loc1_++;
         }
      }
      
      private function onTabUpdate(param1:Event) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc2_:ParkourRewardListUI = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.rewardListUIs.length)
         {
            _loc2_ = this.rewardListUIs[_loc1_] as ParkourRewardListUI;
            _loc2_.visible = this.tabComponent.getCurTab() == _loc1_;
            _loc1_++;
         }
      }
      
      override protected function onClickTarget(param1:String) : void
      {
      }
      
      override protected function onDispose() : void
      {
         var _loc2_:ParkourRewardListUI = null;
         this.tabComponent.removeEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
         this.tabComponent.dispose();
         var _loc1_:int = 0;
         while(_loc1_ < this.rewardListUIs.length)
         {
            _loc2_ = this.rewardListUIs[_loc1_] as ParkourRewardListUI;
            _loc2_.dispose();
            _loc1_++;
         }
      }
   }
}

