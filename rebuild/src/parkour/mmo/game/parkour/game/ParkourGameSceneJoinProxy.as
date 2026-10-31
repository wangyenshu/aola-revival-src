package mmo.game.parkour.game
{
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.game.parkour.dailytask.ParkourDailyTaskLogger;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   
   public class ParkourGameSceneJoinProxy
   {
      
      public function ParkourGameSceneJoinProxy()
      {
         super();
      }
      
      public function joinGame() : void
      {
         var _loc1_:Boolean = ParkourUserData.instance.isFirst;
         var _loc2_:ParkourRoleUserData = ParkourUserData.instance.getSelectedRoleData();
         var _loc3_:ParkourRidePetUserData = ParkourUserData.instance.getSelectedRidePetData();
         var _loc4_:int = ParkourUserData.instance.totalRunDistance;
         var _loc5_:int = ParkourUserData.instance.myRank;
         var _loc6_:int = ParkourUserData.instance.usedField;
         ParkourDailyTaskLogger.instance.logPlayMap(_loc6_);
         ParkourUserData.instance.returnRentRole(_loc2_.id);
         ModalDialogManager.getInstance().clearAll();
         new ParkourGameScene(_loc6_,_loc2_,_loc3_,_loc4_,_loc5_,_loc1_).showPanel();
         ParkourUserData.instance.isFirst = false;
      }
   }
}

