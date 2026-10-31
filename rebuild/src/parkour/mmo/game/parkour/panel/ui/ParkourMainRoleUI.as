package mmo.game.parkour.panel.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.game.parkour.config.ParkourRoleConfig;
   import mmo.game.parkour.data.ParkourUserData;
   import mmo.game.parkour.data.role.ParkourRoleInfo;
   import mmo.game.parkour.data.role.ParkourRoleUserData;
   import mmo.game.parkour.panel.ParkourGetRolePanel;
   import mmo.game.parkour.panel.ParkourUpRolePanel;
   
   public class ParkourMainRoleUI
   {
      
      private static const PreNameOfmcRole:String = "mcRole_";
      
      private static const NumPerPage:int = 7;
      
      private static const MinPage:int = 1;
      
      private static const MaxPage:int = Math.ceil(ParkourRoleConfig.numOfRole / NumPerPage);
      
      private var page:int = 1;
      
      private var container:MovieClip;
      
      private var btnNext:SimpleButton;
      
      private var btnPrev:SimpleButton;
      
      public function ParkourMainRoleUI(param1:MovieClip)
      {
         super();
         this.container = param1;
         this.btnNext = param1.btnNext as SimpleButton;
         this.btnPrev = param1.btnPrev as SimpleButton;
         param1.addEventListener(MouseEvent.CLICK,this.onClick);
         this.setPage(MinPage);
         ParkourUserData.instance.addEventListener(ParkourUserData.OnDataUpdate,this.onDataUpdate);
      }
      
      private function onDataUpdate(param1:Event) : void
      {
         this.refresh();
      }
      
      private function getRoleInfosThisPage() : Array
      {
         var _loc1_:int = 0 + NumPerPage * (this.page - 1);
         return ParkourRoleConfig.getRoleInfos(_loc1_,NumPerPage);
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
      
      public function set visible(param1:Boolean) : void
      {
         this.container.visible = param1;
      }
      
      public function refresh() : void
      {
         this.refreshAllRole();
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
      
      private function refreshAllRole() : void
      {
         var _loc3_:ParkourRoleInfo = null;
         var _loc4_:MovieClip = null;
         var _loc5_:MovieClip = null;
         var _loc6_:MovieClip = null;
         var _loc7_:MovieClip = null;
         var _loc8_:ParkourRoleUserData = null;
         var _loc9_:int = 0;
         var _loc10_:TextField = null;
         var _loc1_:Array = this.getRoleInfosThisPage();
         var _loc2_:int = 0;
         while(_loc2_ < NumPerPage)
         {
            _loc3_ = _loc1_[_loc2_];
            _loc4_ = this.container.getChildByName(PreNameOfmcRole + _loc2_) as MovieClip;
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
               _loc8_ = ParkourUserData.instance.getRoleData(_loc3_.id);
               _loc9_ = _loc8_ != null && _loc8_.isExit ? 1 : 2;
               _loc7_.gotoAndStop(_loc9_);
               _loc10_ = _loc7_.getChildByName("txtLevel") as TextField;
               if(_loc8_ != null && _loc10_ != null)
               {
                  _loc10_.text = "Lv." + _loc8_.level + "";
               }
            }
            _loc4_.addEventListener(MouseEvent.CLICK,this.onClickRole,false);
            _loc2_++;
         }
      }
      
      private function onClickRole(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.currentTarget.name;
         var _loc3_:int = parseInt(_loc2_.substr(PreNameOfmcRole.length));
         var _loc4_:ParkourRoleInfo = this.getRoleInfosThisPage()[_loc3_];
         if(_loc4_ == null)
         {
            return;
         }
         var _loc5_:int = _loc4_.id;
         var _loc6_:String = param1.target.name;
         if(_loc6_ == "btnUpLevel")
         {
            new ParkourUpRolePanel(ParkourUserData.instance.getRoleData(_loc5_),this.refresh).showPanel();
         }
         else if(_loc6_ == "btnGet")
         {
            new ParkourGetRolePanel(_loc4_,this.refresh).showPanel();
         }
         else if(_loc6_ == "mcView")
         {
            ParkourUserData.instance.changeSelectedRole(_loc5_);
            this.refresh();
         }
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
         ParkourUserData.instance.removeEventListener(ParkourUserData.OnDataUpdate,this.onDataUpdate);
      }
   }
}

