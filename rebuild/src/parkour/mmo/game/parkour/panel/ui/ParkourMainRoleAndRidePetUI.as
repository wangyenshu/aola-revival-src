package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import mmo.game.parkour.common.tab.ParkourTabComponent;
   
   public class ParkourMainRoleAndRidePetUI
   {
      
      private var roleAndRidePetTab:ParkourTabComponent;
      
      private var roleUI:ParkourMainRoleUI;
      
      private var ridePetUI:ParkourMainRidePetUI;
      
      public function ParkourMainRoleAndRidePetUI(param1:MovieClip)
      {
         super();
         this.roleUI = new ParkourMainRoleUI(param1.roleContainer);
         this.ridePetUI = new ParkourMainRidePetUI(param1.ridePetContainer);
         this.roleAndRidePetTab = new ParkourTabComponent(param1,2,["mcTabRole","mcTabRidePet"]);
         this.roleAndRidePetTab.addEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
         this.roleAndRidePetTab.showTab(0);
      }
      
      private function onTabUpdate(param1:Event) : void
      {
         this.refreshRoleAndRidePetTab();
      }
      
      public function refresh() : void
      {
         this.roleUI.refresh();
         this.ridePetUI.refresh();
         this.refreshRoleAndRidePetTab();
      }
      
      private function refreshRoleAndRidePetTab() : void
      {
         var _loc1_:Boolean = this.roleAndRidePetTab.getCurTab() == 0;
         this.roleUI.visible = _loc1_;
         this.ridePetUI.visible = !_loc1_;
      }
      
      public function dispose() : void
      {
         this.roleUI.dispose();
         this.ridePetUI.dispose();
         this.roleAndRidePetTab.removeEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
      }
   }
}

