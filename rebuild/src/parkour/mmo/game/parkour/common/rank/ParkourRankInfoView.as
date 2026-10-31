package mmo.game.parkour.common.rank
{
   import flash.display.MovieClip;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.game.parkour.config.ParkourResConfig;
   
   public class ParkourRankInfoView extends MovieClip
   {
      
      private var view:MovieClip;
      
      private var info:ParkourRankInfo;
      
      public function ParkourRankInfoView()
      {
         super();
         this.view = ParkourResConfig.createView(ParkourResConfig.ClsNameOfRankView) as MovieClip;
         addChild(this.view);
      }
      
      public function showInfo(param1:ParkourRankInfo) : void
      {
         visible = param1 != null;
         if(param1 == null)
         {
            return;
         }
         this.info = param1;
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc1_:MovieClip = this.view.getChildByName("mcRank") as MovieClip;
         var _loc2_:TextField = this.view.getChildByName("txtUserName") as TextField;
         var _loc3_:TextField = this.view.getChildByName("txtScore") as TextField;
         _loc1_.gotoAndStop(this.info.rank);
         _loc2_.text = this.info.nickName + "";
         _loc3_.text = this.info.score + "";
      }
      
      public function dispose() : void
      {
         DisplayUtil.stopAndRemove(this.view);
         this.view = null;
         this.info = null;
      }
   }
}

