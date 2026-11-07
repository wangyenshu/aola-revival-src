package mmo.robot.robotmanager
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.pet.rarepetpanel.RarePetTable;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * 稀有亚比搜索仪 of the HELLO menu: the era's rare 亚比 pages (sceneres/rarepetpanel/*, the
    * pages RarePetPanelService shows one at a time, RarePetTable ids 0–7), with arrows to go
    * through all eight. RECONSTRUCTED (the 搜索仪's own panel is lost). The pages are drawn for
    * the stage's corner, as RarePetPanelService puts them (AlignType.NONE at 0, 0).
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
         ModalDialogManager.getInstance().addModalDialog(current, AlignType.NONE, PanelEffect.NONE, true, 0, 0, true);
      }

      public function RareSearch()
      {
         super();
         addChild(holder);
         // Its btnClose, wherever it is in the page (RarePetPanelService's way).
         holder.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            if (e.target is DisplayObject && DisplayObject(e.target).name == "btnClose") close();
         });
         prev = RUI.button("◀", function():void { go(index - 1); }, 36, 36, 0x8FE3FF, 0x1E8FE0, "rareSearchPrev");
         next = RUI.button("▶", function():void { go(index + 1); }, 36, 36, 0x8FE3FF, 0x1E8FE0, "rareSearchNext");
         prev.x = 14;
         next.x = 910;
         prev.y = next.y = 262;
         addChild(prev);
         addChild(next);
         pageText = RUI.text(14, 0xFFFFFF, true);
         pageText.y = 530;
         addChild(pageText);
         go(0);
      }

      private function go(i:int):void
      {
         index = (i + COUNT) % COUNT;
         pageText.text = "稀有亚比搜索仪  " + (index + 1) + "/" + COUNT;
         pageText.x = 480 - pageText.width / 2;
         ProgressFullSprite.show();
         var asked:int = index;
         ResScheduler.getTempResource(RarePetTable.getFileNameByID(index), function(d:DisplayObject, dom:ApplicationDomain = null):void
         {
            ProgressFullSprite.close();
            if (asked != index || parent == null) return;
            if (page != null && page.parent != null) page.parent.removeChild(page);
            page = d;
            page.x = page.y = 0;
            holder.addChild(page);
         }, RarePetTable.getClsNameByID(index));
      }

      public function close():void
      {
         if (parent != null) ModalDialogManager.getInstance().removeModalDialog(this);
         if (current == this) current = null;
      }
   }
}
