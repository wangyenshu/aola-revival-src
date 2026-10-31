package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import mmo.common.utils.tips.TipsManager;
   import mmo.game.parkour.data.ParkourRewardInfo;
   
   public class ParkourRewardBox
   {
      
      private var info:ParkourRewardInfo;
      
      private var view:MovieClip;
      
      public function ParkourRewardBox(param1:MovieClip)
      {
         super();
         this.view = param1;
         param1.gotoAndStop(1);
      }
      
      public function showReward(param1:ParkourRewardInfo) : void
      {
         this.info = param1;
         this.refresh();
      }
      
      public function getInfo() : ParkourRewardInfo
      {
         return this.info;
      }
      
      private function refresh() : void
      {
         this.view.visible = this.info != null;
         if(this.info == null)
         {
            TipsManager.getInstance().removeTips(this.view);
            return;
         }
         var _loc1_:String = this.info.title;
         TipsManager.getInstance().addComplexTips(this.view,_loc1_,"");
      }
      
      public function dispose() : void
      {
         this.view = null;
      }
   }
}

