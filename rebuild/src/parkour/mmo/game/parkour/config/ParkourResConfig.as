package mmo.game.parkour.config
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import mmo.loader.common.datastructures.ResourceObject;
   
   public class ParkourResConfig
   {
      
      public static const PreResPath:String = "game/parkour/";
      
      public static const PreClsName:String = "mmo.game.parkour.view.";
      
      public static const MainPanel:ResourceObject = createResObj("MainPanel","parkour");
      
      public static const PausePanel:ResourceObject = createResObj("PausePanel");
      
      public static const DiePanel:ResourceObject = createResObj("DiePanel");
      
      public static const EndGamePanel:ResourceObject = createResObj("EndGamePanel");
      
      public static const GetRolePanel:ResourceObject = createResObj("GetRolePanel");
      
      public static const UpRolePanel:ResourceObject = createResObj("UpRolePanel");
      
      public static const GetRidePetPanel:ResourceObject = createResObj("GetRidePetPanel");
      
      public static const UpRidePetPanel:ResourceObject = createResObj("UpRidePetPanel");
      
      public static const SelectMapPanel:ResourceObject = createResObj("SelectMapPanel");
      
      public static const LackMoneyPanel:ResourceObject = createResObj("LackMoneyPanel");
      
      public static const BuyMoneyPanel:ResourceObject = createResObj("BuyMoneyPanel");
      
      public static const MemberBuyMoneyConfirmPanel:ResourceObject = createResObj("MemberBuyMoneyConfirmPanel");
      
      public static const NotMemberBuyMoneyConfirmPanel:ResourceObject = createResObj("NotMemberBuyMoneyConfirmPanel");
      
      public static const MemberBuyLoveConfirmPanel:ResourceObject = createResObj("MemberBuyLoveConfirmPanel");
      
      public static const BuyLovePanel:ResourceObject = createResObj("BuyLovePanel");
      
      public static const RewardPanel:ResourceObject = createResObj("RewardPanel");
      
      public static const DailySignUpPanel:ResourceObject = createResObj("DailySignUpPanel");
      
      public static const DailyTaskPanel:ResourceObject = createResObj("DailyTaskPanel","parkourpanel1");
      
      public static const RentConfirmPanel:ResourceObject = createResObj("RentConfirmPanel");
      
      public static const RewardListPanel:ResourceObject = createResObj("RewardListPanel","parkourpanelrewardlist");
      
      public static const ClsNameOfRankView:String = PreClsName + "panel.RankView";
      
      public static const ClsNameOfDailyTaskView:String = PreClsName + "panel.DailyTaskView";
      
      public static const FirstMovie:ResourceObject = new ResourceObject(PreResPath + "parkourfirstmovie",PreClsName + "FirstMovie");
      
      public function ParkourResConfig()
      {
         super();
      }
      
      private static function createResObj(param1:String, param2:String = "parkourpanel") : ResourceObject
      {
         return new ResourceObject(PreResPath + param2,PreClsName + "panel." + param1);
      }
      
      public static function createView(param1:String) : DisplayObject
      {
         var _loc2_:Class = ApplicationDomain.currentDomain.getDefinition(param1) as Class;
         return new _loc2_() as DisplayObject;
      }
   }
}

