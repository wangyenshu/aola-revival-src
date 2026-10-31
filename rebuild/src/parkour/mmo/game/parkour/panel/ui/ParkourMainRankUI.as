package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import mmo.game.parkour.common.rank.ParkourScrollRankComponent;
   import mmo.game.parkour.common.tab.ParkourTabComponent;
   import mmo.game.parkour.helper.ParkourHelper;
   
   public class ParkourMainRankUI
   {
      
      private var tabComponent:ParkourTabComponent;
      
      private var allRankComponent:ParkourScrollRankComponent;
      
      public function ParkourMainRankUI(param1:MovieClip)
      {
         super();
         this.tabComponent = new ParkourTabComponent(param1,1);
         this.tabComponent.addEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
         this.allRankComponent = new ParkourScrollRankComponent(param1.mcRankOfAll);
         this.tabComponent.showTab(0);
      }
      
      private function onTabUpdate(param1:Event) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:Boolean = this.tabComponent.getCurTab() == 0;
         this.allRankComponent.visible = _loc1_;
      }
      
      public function parseParams(param1:Object) : void
      {
         this.allRankComponent.updateRanks(ParkourHelper.parseRankDatas(param1.l));
      }
      
      public function dispose() : void
      {
         this.allRankComponent.dispose();
         this.tabComponent.dispose();
      }
   }
}

