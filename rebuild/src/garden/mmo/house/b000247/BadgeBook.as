package mmo.house.b000247
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * The 家园 bar's 勋章: the 勋章 page of the player card (usercard/usercard_badge, its
    * UserCardBadgeService's BadgePanel: the badges of BadgeData, the owner's got ones in colour,
    * when and how hard) for the garden's owner. The page was a tab of the card and has no close
    * button of its own: it is shown over the garden with one (REVIVAL).
    */
   public class BadgeBook extends Sprite
   {
      private static var current:BadgeBook;

      public static function show(owner:String):void
      {
         hide();
         var book:BadgeBook = new BadgeBook();
         current = book;
         ServiceContainer.instance.tryGetService("UserCardBadgeService", function(svc:IService, o:Object):void
         {
            if (current != book) return;
            var page:Sprite = null;
            try { page = Object(svc).getBadgePanel(owner) as Sprite; }
            catch (e:Error) { RLog.error("badge panel", e); }
            if (page == null) return;
            book.put(page);
         });
      }

      public static function hide():void
      {
         if (current != null && current.parent != null) current.parent.removeChild(current);
         current = null;
      }

      public function BadgeBook()
      {
         super();
         name = "badgeBook";
         addChild(RUI.dim(hide));
      }

      private function put(page:Sprite):void
      {
         var holder:Sprite = new Sprite();
         holder.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         holder.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
         holder.addChild(page);
         var b:Rectangle = page.getBounds(page);
         page.x = -b.left;
         page.y = -b.top;
         holder.x = int((960 - b.width) / 2);
         holder.y = int((560 - b.height) / 2) - 6;
         addChild(holder);
         var x:DisplayObject = closeButton();
         x.x = b.width - 22;
         x.y = 18;
         holder.addChild(x);
         LayerManager.getBaseTop().addChild(this);
      }

      private static function closeButton():Sprite
      {
         var c:Sprite = new Sprite();
         c.name = "badgeClose";
         c.buttonMode = true;
         c.graphics.lineStyle(2.5, 0xFFFFFF);
         c.graphics.beginFill(0xD9452B);
         c.graphics.drawCircle(0, 0, 14);
         c.graphics.endFill();
         c.graphics.lineStyle(3, 0xFFFFFF);
         c.graphics.moveTo(-5, -5);
         c.graphics.lineTo(5, 5);
         c.graphics.moveTo(5, -5);
         c.graphics.lineTo(-5, 5);
         c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            hide();
         });
         return c;
      }
   }
}
