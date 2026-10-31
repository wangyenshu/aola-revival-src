package mmo.game.parkour.common.tab
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   
   public class ParkourTabComponent extends EventDispatcher
   {
      
      public static const OnTabUpdate:String = "OnTabUpdate";
      
      private static const MinTabIndex:int = 0;
      
      private static const PreNameOfMcTab:String = "mcTab_";
      
      private var curTab:int = -1;
      
      private var numOfTab:int = 0;
      
      private var container:MovieClip;
      
      private var unSelectTips:Array = null;
      
      private var names:Array;
      
      public function ParkourTabComponent(param1:MovieClip, param2:int, param3:Array = null, param4:Array = null)
      {
         var _loc5_:int = 0;
         super();
         this.container = param1;
         this.numOfTab = param2;
         this.unSelectTips = param4;
         if(param3 != null)
         {
            this.names = param3;
         }
         else
         {
            this.names = [];
            _loc5_ = 0;
            while(_loc5_ < param2)
            {
               this.names.push(PreNameOfMcTab + _loc5_);
               _loc5_++;
            }
         }
         this.initMcTab();
      }
      
      public function showTab(param1:int) : void
      {
         this.setTab(param1);
      }
      
      public function getCurTab() : int
      {
         return this.curTab;
      }
      
      private function initMcTab() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = MinTabIndex;
         while(_loc1_ < MinTabIndex + this.numOfTab)
         {
            _loc2_ = this.container.getChildByName(this.names[_loc1_]) as MovieClip;
            _loc2_.addEventListener(MouseEvent.CLICK,this.onClickTab);
            _loc1_++;
         }
      }
      
      private function setTab(param1:int) : void
      {
         if(param1 < MinTabIndex)
         {
            return;
         }
         this.curTab = param1;
         this.refresh();
         dispatchEvent(new Event(OnTabUpdate));
      }
      
      private function refresh() : void
      {
         this.refreshTab();
      }
      
      private function refreshTab() : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:int = 0;
         var _loc4_:String = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.numOfTab)
         {
            _loc2_ = this.container.getChildByName(this.names[_loc1_]) as MovieClip;
            _loc3_ = _loc1_ == this.curTab ? 2 : 1;
            _loc2_.gotoAndStop(_loc3_);
            TipsManager.getInstance().removeTips(_loc2_);
            if(_loc1_ != this.curTab && this.unSelectTips != null)
            {
               _loc4_ = this.unSelectTips[_loc1_];
               TipsManager.getInstance().addTips(_loc2_,_loc4_);
            }
            _loc1_++;
         }
      }
      
      private function onClickTab(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.currentTarget.name;
         var _loc3_:int = this.names.indexOf(_loc2_);
         if(this.curTab != _loc3_)
         {
            this.setTab(_loc3_);
         }
      }
      
      public function dispose() : void
      {
         var _loc2_:MovieClip = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.numOfTab)
         {
            _loc2_ = this.container.getChildByName(this.names[_loc1_]) as MovieClip;
            _loc2_.removeEventListener(MouseEvent.CLICK,this.onClickTab);
            _loc1_++;
         }
      }
   }
}

