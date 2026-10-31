package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   
   public class ParkourRewardListUI
   {
      
      private static const MinPage:int = 1;
      
      private var view:MovieClip;
      
      private var curPage:int;
      
      public function ParkourRewardListUI(param1:MovieClip)
      {
         super();
         this.view = param1;
         this.view.addEventListener(MouseEvent.CLICK,this.onClick);
         this.setCurPage(MinPage);
         this.refresh();
      }
      
      private function get maxPage() : int
      {
         return this.view.totalFrames;
      }
      
      private function refresh() : void
      {
         this.view.gotoAndStop(this.curPage);
         this.refreshButton(this.view.btnNext,this.curPage >= this.maxPage);
         this.refreshButton(this.view.btnPrev,this.curPage <= MinPage);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnNext")
         {
            this.setCurPage(this.curPage + 1);
            this.refresh();
         }
         else if(_loc2_ == "btnPrev")
         {
            this.setCurPage(this.curPage - 1);
            this.refresh();
         }
      }
      
      private function refreshButton(param1:SimpleButton, param2:Boolean) : void
      {
         if(param2)
         {
            DisplayUtil.applyGray(param1);
         }
         else
         {
            DisplayUtil.clearFilters(param1);
         }
      }
      
      private function setCurPage(param1:int) : void
      {
         if(param1 <= MinPage)
         {
            this.curPage = MinPage;
         }
         else if(param1 >= this.maxPage)
         {
            this.curPage = this.maxPage;
         }
         else
         {
            this.curPage = param1;
         }
      }
      
      public function set visible(param1:Boolean) : void
      {
         this.view.visible = param1;
      }
      
      public function dispose() : void
      {
         this.view = null;
      }
   }
}

