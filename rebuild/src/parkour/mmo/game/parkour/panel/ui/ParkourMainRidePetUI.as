package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.game.parkour.config.ParkourRidePetConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.ridepet.ParkourRidePetInfo;
   import mmo.game.parkour.data.ridepet.ParkourRidePetUserData;
   import mmo.game.parkour.panel.ParkourGetRidePetPanel;
   import mmo.game.parkour.panel.ParkourUpRidePetPanel;
   
   public class ParkourMainRidePetUI
   {
      
      private static const PreNameOfmcRidePet:String = "mcRidePet_";
      
      private static const NumPerPage:int = 7;
      
      private static const MinPage:int = 1;
      
      private static const MaxPage:int = Math.ceil(ParkourRidePetConfig.numOfRidePet / NumPerPage);
      
      private var page:int = 1;
      
      private var container:MovieClip;
      
      private var btnNext:SimpleButton;
      
      private var btnPrev:SimpleButton;
      
      public function ParkourMainRidePetUI(param1:MovieClip)
      {
         super();
         this.container = param1;
         this.btnNext = param1.btnNext as SimpleButton;
         this.btnPrev = param1.btnPrev as SimpleButton;
         param1.addEventListener(MouseEvent.CLICK,this.onClick);
         this.setPage(MinPage);
      }
      
      private function getRidePetInfosThisPage() : Array
      {
         var _loc1_:int = 0 + NumPerPage * (this.page - 1);
         return ParkourRidePetConfig.getRidePetInfos(_loc1_,NumPerPage);
      }
      
      private function setPage(param1:int) : void
      {
         if(param1 < MinPage)
         {
            this.page = MinPage;
         }
         else if(param1 > MaxPage)
         {
            this.page = MaxPage;
         }
         else
         {
            this.page = param1;
         }
         this.refresh();
      }
      
      public function refresh() : void
      {
         this.refreshAllRidePet();
         this.refreshButton(this.btnNext,this.page >= MaxPage);
         this.refreshButton(this.btnPrev,this.page <= MinPage);
      }
      
      private function refreshButton(param1:SimpleButton, param2:Boolean) : void
      {
         param1.enabled = !param2;
         if(param2)
         {
            DisplayUtil.applyGray(param1);
         }
         else
         {
            DisplayUtil.clearFilters(param1);
         }
      }
      
      private function refreshAllRidePet() : void
      {
         var _loc3_:ParkourRidePetInfo = null;
         var _loc4_:MovieClip = null;
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc8_:ParkourRidePetUserData = null;
         var _loc9_:int = 0;
         var _loc10_:TextField = null;
         var _loc1_:Array = this.getRidePetInfosThisPage();
         var _loc2_:int = 0;
         while(_loc2_ < NumPerPage)
         {
            _loc3_ = _loc1_[_loc2_];
            _loc4_ = this.container.getChildByName(PreNameOfmcRidePet + _loc2_) as MovieClip;
            _loc5_ = _loc4_.getChildByName("mcUnKnow") as MovieClip;
            _loc6_ = _loc4_.getChildByName("mcView") as MovieClip;
            _loc7_ = _loc4_.getChildByName("mcDes") as MovieClip;
            _loc6_.buttonMode = true;
            _loc6_.visible = _loc3_ != null;
            _loc7_.visible = _loc3_ != null;
            _loc5_.visible = _loc3_ == null;
            _loc6_.gotoAndStop(1);
            _loc7_.gotoAndStop(1);
            _loc6_.mouseChildren = false;
            if(_loc3_ != null)
            {
               _loc6_.gotoAndStop(_loc3_.id);
               _loc8_ = ParkourUserData.instance.getRidePetData(_loc3_.id);
               _loc9_ = _loc8_ != null ? 1 : 2;
               _loc7_.gotoAndStop(_loc9_);
               if(_loc8_ != null)
               {
                  _loc10_ = _loc7_.getChildByName("txtLevel") as TextField;
                  _loc10_.text = "Lv." + _loc8_.level + "";
               }
            }
            _loc4_.addEventListener(MouseEvent.CLICK,this.onClickRidePet,false);
            _loc2_++;
         }
      }
      
      private function onClickRidePet(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.currentTarget.name;
         var _loc3_:int = parseInt(_loc2_.substr(PreNameOfmcRidePet.length));
         var _loc4_:ParkourRidePetInfo = this.getRidePetInfosThisPage()[_loc3_];
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:int = _loc4_.id;
         var _loc6_:String = param1.target.name;
         if(_loc6_ == "btnUpLevel")
         {
            new ParkourUpRidePetPanel(ParkourUserData.instance.getRidePetData(_loc5_),this.refresh).showPanel();
         }
         else if(_loc6_ == "btnGet")
         {
            new ParkourGetRidePetPanel(_loc4_,this.refresh).showPanel();
         }
         else if(_loc6_ == "mcView")
         {
            ParkourUserData.instance.changeSelectedRidePet(_loc5_);
            this.refresh();
         }
      }
      
      public function set visible(param1:Boolean) : void
      {
         this.container.visible = param1;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.target as SimpleButton;
         if(_loc2_ == this.btnPrev)
         {
            this.setPage(this.page - 1);
         }
         else if(_loc2_ == this.btnNext)
         {
            this.setPage(this.page + 1);
         }
      }
      
      public function dispose() : void
      {
         this.container = null;
      }
   }
}

