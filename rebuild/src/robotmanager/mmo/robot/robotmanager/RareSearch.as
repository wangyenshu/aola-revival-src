package mmo.robot.robotmanager
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.pet.rarepetpanel.RarePetTable;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * 稀有亚比搜索仪 of the HELLO menu: the era's rare 亚比 pages (sceneres/rarepetpanel/*, the
    * pages RarePetPanelService shows one at a time, RarePetTable ids 0–7), with arrows to go
    * through all eight. RECONSTRUCTED (the 搜索仪's own panel is lost).
    */
   public class RareSearch extends Sprite
   {
      private static const COUNT:int = 8;
      private static var current:RareSearch;

      private var index:int;
      private var page:DisplayObject;
      private var pageText:TextField;
      private var holder:Sprite = new Sprite();
      private var prev:Sprite;
      private var next:Sprite;

      public static function show():void
      {
         if (current != null) current.close();
         current = new RareSearch();
         ModalDialogManager.getInstance().addModalDialog(current);
      }

      public function RareSearch()
      {
         super();
         addChild(holder);
         prev = RUI.button("◀", function():void { go(index - 1); }, 36, 36, 0x8FE3FF, 0x1E8FE0, "rareSearchPrev");
         next = RUI.button("▶", function():void { go(index + 1); }, 36, 36, 0x8FE3FF, 0x1E8FE0, "rareSearchNext");
         prev.x = -250;
         next.x = 214;
         prev.y = next.y = -18;
         addChild(prev);
         addChild(next);
         pageText = RUI.text(14, 0xFFFFFF, true);
         pageText.y = 190;
         addChild(pageText);
         go(0);
      }

      private function go(i:int):void
      {
         index = (i + COUNT) % COUNT;
         pageText.text = "稀有亚比搜索仪  " + (index + 1) + "/" + COUNT;
         pageText.x = -pageText.width / 2;
         ProgressFullSprite.show();
         var asked:int = index;
         ResScheduler.getTempResource(RarePetTable.getFileNameByID(index), function(d:DisplayObject, dom:ApplicationDomain = null):void
         {
            ProgressFullSprite.close();
            if (asked != index || parent == null) return;
            if (page != null && page.parent != null) page.parent.removeChild(page);
            page = d;
            // Centred by what it draws (the pages draw away from their origin).
            var b:Rectangle = page.getBounds(page);
            page.x = -b.x - b.width / 2;
            page.y = -b.y - b.height / 2;
            holder.addChild(page);
            prev.x = -b.width / 2 - 44;
            next.x = b.width / 2 + 8;
            pageText.y = b.height / 2 + 6;
            var c:DisplayObject = page is DisplayObjectContainer ? DisplayObjectContainer(page).getChildByName("btnClose") : null;
            if (c != null) c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         }, RarePetTable.getClsNameByID(index));
      }

      public function close():void
      {
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }
   }
}
