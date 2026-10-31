package mmo.game.parkour.common.page
{
   import flash.display.DisplayObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.event.BtEventDispatcher;
   import mmo.util.component.page.PageComponentEvent;
   
   public class ParkourPageComponent extends BtEventDispatcher
   {
      
      private var pageDatas:ParkourPageDatas;
      
      private var prevBtn:DisplayObject;
      
      private var nextBtn:DisplayObject;
      
      private var pageText:TextField;
      
      private var pageTextFormat:String;
      
      private var btnGray:Boolean;
      
      private var endBtn:DisplayObject = null;
      
      private var firstBtn:DisplayObject = null;
      
      private var currentPage:int;
      
      public function ParkourPageComponent(param1:Array, param2:int, param3:DisplayObject = null, param4:DisplayObject = null, param5:TextField = null, param6:DisplayObject = null, param7:DisplayObject = null)
      {
         super();
         this.prevBtn = param3;
         this.nextBtn = param4;
         this.pageText = param5;
         this.endBtn = param6;
         this.firstBtn = param7;
         this.pageDatas = new ParkourPageDatas(param1,param2);
         this.currentPage = 1;
         this.setPageTextFormat();
         this.setBtnDisableStyle();
         this.initBtn();
      }
      
      public function get getTotalPage() : int
      {
         return this.pageDatas.getTotalPage;
      }
      
      public function get getCurrentPage() : int
      {
         return this.currentPage;
      }
      
      public function deleteData(param1:Object) : void
      {
         this.pageDatas.deleteData(param1);
      }
      
      public function get totalDataCount() : int
      {
         return this.pageDatas.totalDataCount();
      }
      
      public function setPageTextFormat(param1:String = "{0}/{1}") : void
      {
         if(param1.indexOf("{0}") < 0 || param1.indexOf("{1}") < 0)
         {
            throw new Error("pageTextFormat error:" + param1);
         }
         this.pageTextFormat = param1;
         this.refreshPageText();
      }
      
      public function setBtnDisableStyle(param1:Boolean = true) : void
      {
         this.btnGray = param1;
         this.refreshBtn();
      }
      
      public function updateData(param1:Array, param2:Boolean = true, param3:int = -1) : void
      {
         this.pageDatas.updateData(param1,param3);
         if(param2)
         {
            this.currentPage = 1;
         }
         else if(this.currentPage > this.getTotalPage)
         {
            this.currentPage = this.getTotalPage;
         }
         this.refreshPageText();
         this.refreshBtn();
      }
      
      private function refreshPageText() : void
      {
         if(this.pageText == null)
         {
            return;
         }
         var _loc1_:String = this.pageTextFormat.replace("{0}",this.currentPage.toString()).replace("{1}",this.getTotalPage.toString());
         this.pageText.text = _loc1_;
      }
      
      private function initBtn() : void
      {
         if(this.prevBtn != null)
         {
            this.prevBtn.addEventListener(MouseEvent.CLICK,this.onClickPrev);
         }
         if(this.nextBtn != null)
         {
            this.nextBtn.addEventListener(MouseEvent.CLICK,this.onClickNext);
         }
         if(this.firstBtn != null)
         {
            this.firstBtn.addEventListener(MouseEvent.CLICK,this.onClickFirst);
         }
         if(this.endBtn != null)
         {
            this.endBtn.addEventListener(MouseEvent.CLICK,this.onClickEnd);
         }
      }
      
      private function refreshBtn() : void
      {
         if(this.btnGray)
         {
            this.updateOneButton(this.prevBtn,this.currentPage <= 1);
            this.updateOneButton(this.nextBtn,this.currentPage >= this.getTotalPage);
            this.updateOneButton(this.firstBtn,this.currentPage <= 1);
            this.updateOneButton(this.endBtn,this.currentPage >= this.getTotalPage);
         }
      }
      
      private function updateOneButton(param1:DisplayObject, param2:Boolean) : void
      {
         if(param1 == null)
         {
            return;
         }
         if(param2)
         {
            this.grayButton(param1);
         }
         else
         {
            this.clearGrayButton(param1);
         }
      }
      
      private function clearGrayButton(param1:DisplayObject) : void
      {
         param1.filters = [];
         if(param1 is Sprite)
         {
            Sprite(param1).buttonMode = true;
         }
         else if(param1 is SimpleButton)
         {
            SimpleButton(param1).enabled = true;
         }
      }
      
      private function grayButton(param1:DisplayObject) : void
      {
         DisplayUtil.applyGray(param1);
         if(param1 is Sprite)
         {
            Sprite(param1).buttonMode = false;
         }
         else if(param1 is SimpleButton)
         {
            SimpleButton(param1).enabled = false;
         }
      }
      
      private function onClickPrev(param1:MouseEvent) : void
      {
         if(this.currentPage <= 1)
         {
            return;
         }
         --this.currentPage;
         this.refreshBtn();
         this.refreshPageText();
         this.dispatchEvent(new PageComponentEvent(PageComponentEvent.ON_PAGE_CHANGE,{}));
      }
      
      private function onClickFirst(param1:MouseEvent) : void
      {
         if(this.currentPage <= 1)
         {
            return;
         }
         this.currentPage = 1;
         this.refreshBtn();
         this.refreshPageText();
         this.dispatchEvent(new PageComponentEvent(PageComponentEvent.ON_PAGE_CHANGE,{}));
      }
      
      private function onClickNext(param1:MouseEvent) : void
      {
         if(this.currentPage >= this.getTotalPage)
         {
            return;
         }
         ++this.currentPage;
         this.refreshBtn();
         this.refreshPageText();
         this.dispatchEvent(new PageComponentEvent(PageComponentEvent.ON_PAGE_CHANGE,{}));
      }
      
      private function onClickEnd(param1:MouseEvent) : void
      {
         if(this.currentPage >= this.getTotalPage)
         {
            return;
         }
         this.currentPage = this.getTotalPage;
         this.refreshBtn();
         this.refreshPageText();
         this.dispatchEvent(new PageComponentEvent(PageComponentEvent.ON_PAGE_CHANGE,{}));
      }
      
      public function getCurrentPageData() : Array
      {
         return this.pageDatas.getPageData(this.currentPage);
      }
      
      public function setCurrentPage(param1:int) : void
      {
         if(param1 <= 0 || param1 > this.getTotalPage)
         {
            return;
         }
         this.currentPage = param1;
         this.refreshBtn();
         this.refreshPageText();
         this.dispatchEvent(new PageComponentEvent(PageComponentEvent.ON_PAGE_CHANGE,{}));
      }
      
      public function disposeComponent() : void
      {
         if(this.prevBtn != null)
         {
            this.prevBtn.removeEventListener(MouseEvent.CLICK,this.onClickPrev);
         }
         if(this.nextBtn != null)
         {
            this.nextBtn.removeEventListener(MouseEvent.CLICK,this.onClickNext);
         }
         if(this.firstBtn != null)
         {
            this.firstBtn.removeEventListener(MouseEvent.CLICK,this.onClickFirst);
         }
         if(this.endBtn != null)
         {
            this.endBtn.removeEventListener(MouseEvent.CLICK,this.onClickEnd);
         }
      }
   }
}

