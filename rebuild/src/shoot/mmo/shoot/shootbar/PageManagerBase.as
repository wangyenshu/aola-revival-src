package mmo.shoot.shootbar
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.ServiceContainer;
   
   public class PageManagerBase extends MovieClip
   {
      
      public static const onPageChanged:* = "onPageChanged";
      
      public var btnDisNext:SimpleButton;
      
      public var btnDisPrev:SimpleButton;
      
      public var btnNext:SimpleButton;
      
      public var btnPrev:SimpleButton;
      
      public var txtPageInfo:TextField;
      
      public var pageSize:int = 10;
      
      private var _recordCount:int;
      
      private var _pageCount:int;
      
      private var _pageIndex:int = 0;
      
      private var disNext:DisplayObject;
      
      private var disPrev:DisplayObject;
      
      private var txtPage:TextField;
      
      private var _skinSvr:NoSkins = NoSkins.instance;
      
      public function PageManagerBase()
      {
         super();
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
         CommonEventDispatcher.instance.addEventListener(NoSkins.CHANGE,this.onChangeSkin);
         this.disNext = this.getChildByName("btnDisNext");
         this.disPrev = this.getChildByName("btnDisPrev");
         this.txtPage = this.getChildByName("txtPageInfo") as TextField;
      }
      
      private function onChangeSkin(param1:CommonEvent) : void
      {
         this.gotoAndStop(this._skinSvr.getUsingSkinId() + 1);
      }
      
      public function get recordCount() : int
      {
         return this._recordCount;
      }
      
      public function set recordCount(param1:int) : void
      {
         this._recordCount = param1;
         this._pageCount = Math.ceil(param1 / this.pageSize);
      }
      
      public function reset() : void
      {
         this.onChanging();
      }
      
      public function get pageIndex() : int
      {
         return this._pageIndex;
      }
      
      public function set pageIndex(param1:int) : void
      {
         this._pageIndex = param1;
         this.onChanging();
      }
      
      public function get pageCount() : int
      {
         return this._pageCount;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:SimpleButton = param1.target as SimpleButton;
         if(_loc2_ == null)
         {
            return;
         }
         if(this._pageCount <= 1)
         {
            return;
         }
         switch(_loc2_.name)
         {
            case "btnPrev":
               if(this._pageIndex == 0)
               {
                  return;
               }
               --this._pageIndex;
               this.onChanging();
               break;
            case "btnNext":
               if(this._pageIndex == this._pageCount - 1)
               {
                  return;
               }
               ++this._pageIndex;
               this.onChanging();
         }
      }
      
      private function onChanging() : void
      {
         if(this.pageCount > 0)
         {
            if(this.pageIndex == 0)
            {
               this.addChild(this.disPrev);
            }
            else if(this.disPrev.parent != null)
            {
               this.removeChild(this.disPrev);
            }
            if(this.pageIndex >= this.pageCount - 1)
            {
               this.addChild(this.disNext);
            }
            else if(this.disNext.parent != null)
            {
               this.removeChild(this.disNext);
            }
            this.txtPage.text = this._pageIndex + 1 + "/" + this._pageCount;
         }
         else
         {
            this.addChild(this.disPrev);
            this.addChild(this.disNext);
            this.txtPage.text = "1/1";
         }
         this.dispatchEvent(new Event(onPageChanged));
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
   }
}

