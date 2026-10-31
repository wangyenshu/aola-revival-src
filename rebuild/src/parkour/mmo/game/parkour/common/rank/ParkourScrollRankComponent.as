package mmo.game.parkour.common.rank
{
   import fl.containers.ScrollPane;
   import fl.controls.ScrollPolicy;
   import flash.display.MovieClip;
   import mmo.common.DisplayUtil;
   
   public class ParkourScrollRankComponent
   {
      
      private var container:MovieClip;
      
      private var source:MovieClip;
      
      private var datas:Array = [];
      
      private var infoViews:Array = [];
      
      private var scrollPane:ScrollPane;
      
      public function ParkourScrollRankComponent(param1:MovieClip)
      {
         super();
         this.container = param1;
         this.source = param1.getChildByName("mcSource") as MovieClip;
         this.scrollPane = new ScrollPane();
         this.scrollPane.x = this.source.x;
         this.scrollPane.y = this.source.y;
         this.scrollPane.horizontalScrollPolicy = ScrollPolicy.OFF;
         this.scrollPane.width = this.source.width;
         this.scrollPane.height = this.source.height;
         this.scrollPane.source = this.source;
         param1.addChild(this.scrollPane);
      }
      
      public function updateRanks(param1:Array) : void
      {
         this.datas = param1;
         this.refresh();
      }
      
      private function refresh() : void
      {
         var _loc3_:ParkourRankInfoView = null;
         var _loc4_:ParkourRankInfo = null;
         var _loc1_:int = Math.max(this.datas.length,this.infoViews.length);
         var _loc2_:int = 0;
         while(_loc2_ < _loc1_)
         {
            _loc3_ = this.getInfoView(_loc2_);
            _loc4_ = this.datas[_loc2_] as ParkourRankInfo;
            _loc3_.showInfo(_loc4_);
            _loc3_.x = 10;
            _loc3_.y = _loc2_ * 30;
            this.source.addChild(_loc3_);
            _loc2_++;
         }
         this.scrollPane.update();
      }
      
      private function getInfoView(param1:int) : ParkourRankInfoView
      {
         var _loc2_:ParkourRankInfoView = this.infoViews[param1] as ParkourRankInfoView;
         if(_loc2_ == null)
         {
            _loc2_ = new ParkourRankInfoView();
            this.infoViews[param1] = _loc2_;
         }
         return _loc2_;
      }
      
      public function set visible(param1:Boolean) : void
      {
         this.container.visible = param1;
      }
      
      public function dispose() : void
      {
         var _loc2_:ParkourRankInfoView = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.infoViews.length)
         {
            _loc2_ = this.infoViews[_loc1_] as ParkourRankInfoView;
            _loc2_.dispose();
            _loc1_++;
         }
         DisplayUtil.stopAndRemove(this.scrollPane);
         this.scrollPane = null;
         this.container = null;
      }
   }
}

