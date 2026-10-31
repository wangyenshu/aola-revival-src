package mmo.game.parkour.panel
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.game.parkour.client.ParkourClient;
   import mmo.game.parkour.common.panel.ParkourPanelBase;
   import mmo.game.parkour.common.tab.ParkourTabComponent;
   import mmo.game.parkour.config.ParkourResConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.game.ParkourGameSceneJoinProxy;
   
   public class ParkourSelectMapPanel extends ParkourPanelBase
   {
      
      private var tabComponent:ParkourTabComponent;
      
      public function ParkourSelectMapPanel()
      {
         super(ParkourResConfig.SelectMapPanel);
      }
      
      private function get field() : int
      {
         return ParkourUserData.instance.usedField;
      }
      
      override protected function onShowPanel() : void
      {
         this.tabComponent = new ParkourTabComponent(panel,4);
         this.tabComponent.addEventListener(ParkourTabComponent.OnTabUpdate,this.onTabUpdate);
         this.tabComponent.showTab(ParkourUserData.instance.usedField);
         this.refresh();
         showThisPanel();
      }
      
      private function onTabUpdate(param1:Event) : void
      {
         ParkourUserData.instance.usedField = this.tabComponent.getCurTab();
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:MovieClip = panel.getChildByName("mcField") as MovieClip;
         _loc1_.gotoAndStop(this.field + 1);
      }
      
      override protected function onClickTarget(param1:String) : void
      {
         if(param1 == "btnPlay")
         {
            this.startGame();
         }
      }
      
      private function startGame() : void
      {
         var _loc1_:ParkourRoleUserData = ParkourUserData.instance.getSelectedRoleData();
         var _loc2_:ParkourRidePetUserData = ParkourUserData.instance.getSelectedRidePetData();
         var _loc3_:Boolean = !_loc1_.isExit && ParkourUserData.instance.isRentingRole(_loc1_.id);
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(ParkourClient.CmdStartGame,this.onCmdStartGame);
         ParkourClient.startGame(_loc1_.id,_loc2_.info.id,_loc3_);
      }
      
      private function onCmdStartGame(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(ParkourClient.CmdStartGame,this.onCmdStartGame);
         var _loc2_:int = int(param1.params.res);
         if(_loc2_ == 1)
         {
            close();
            new ParkourGameSceneJoinProxy().joinGame();
         }
         else
         {
            NewDialog.showFailMessage("你的星星能量爱心不足!!");
         }
      }
      
      override protected function onDispose() : void
      {
         this.tabComponent.dispose();
      }
   }
}

