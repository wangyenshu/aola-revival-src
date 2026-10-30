package mmo.housemenu
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;

   /**
    * REBUILT. 购买手册 while decorating: pointing at it unfolds the furniture
    * catalogs (精品家饰 catalog201010, 安娜时尚空间 catalog201003, 种植手册
    * catalog201102), each opened in the rebuilt catalog books.
    */
   public class BtnCatalog extends MovieClip
   {
      public var bg:MovieClip;
      public var btnAll:SimpleButton;
      public var viewMc:MovieClip;

      public function BtnCatalog()
      {
         super();
         if (bg) bg.visible = false;
         if (viewMc) viewMc.visible = false;
         addEventListener(MouseEvent.ROLL_OVER, onOver);
         addEventListener(MouseEvent.ROLL_OUT, onOut);
         addEventListener(MouseEvent.CLICK, onClick);
      }

      private function onOver(e:MouseEvent):void
      {
         if (bg) bg.visible = true;
         if (viewMc) viewMc.visible = true;
      }

      private function onOut(e:MouseEvent):void
      {
         if (bg) bg.visible = false;
         if (viewMc) viewMc.visible = false;
      }

      private function onClick(e:MouseEvent):void
      {
         e.stopImmediatePropagation();
         var name:String = DisplayObject(e.target).name;
         var no:String = {btn201010: "catalog201010", btn201003: "catalog201003", btn201102: "catalog201102", btnAll: "catalog201010"}[name];
         if (no == null) return;
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService, function(svc:IService, o:Object):void
         {
            Object(svc).showPage(no);
         });
      }

      public function dispose():void
      {
         removeEventListener(MouseEvent.ROLL_OVER, onOver);
         removeEventListener(MouseEvent.ROLL_OUT, onOut);
         removeEventListener(MouseEvent.CLICK, onClick);
      }
   }
}
