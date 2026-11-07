package mmo.control
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RUI;
   import mmo.revival.SavePanels;

   /**
    * REVIVAL (not of 2013). The bar's 存档 of a mod played as a game of its own (ControlBar.standalone):
    * the 工具箱's 导出存档 and 导入存档 and nothing else of it. The game is kept in the browser as it
    * goes; the file takes it to another browser or computer, or keeps a copy.
    */
   public class SaveMenu extends Sprite
   {
      private static const W:int = 340;
      private static const H:int = 176;
      private static var current:SaveMenu;

      public static function toggle():void
      {
         if (current != null && current.parent != null)
         {
            current.close();
            return;
         }
         current = new SaveMenu();
         LayerManager.getBaseTop().addChild(current);
      }

      public function SaveMenu()
      {
         super();
         name = "saveMenu";
         addChild(RUI.dim(close));
         var box:Sprite = RUI.panel(W, H, "存档", close, "saveMenuClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         var t:TextField = RUI.text(13, RUI.BLUE, false, W - 48);
         t.text = "进度会自动保存在这个浏览器里。导出存档可以把进度存成文件，换浏览器或换电脑时导入，就能接着玩。";
         t.x = 24;
         t.y = 52;
         box.addChild(t);
         var ex:Sprite = RUI.button("导出存档", function():void { close(); SavePanels.exportSave(); }, 110, 28, 0x6CC0F5, 0x2E86D6, "saveMenuExport");
         ex.x = W / 2 - 122;
         ex.y = H - 52;
         box.addChild(ex);
         var im:Sprite = RUI.button("导入存档", function():void { close(); SavePanels.importSave(); }, 110, 28, 0x6CC0F5, 0x2E86D6, "saveMenuImport");
         im.x = W / 2 + 12;
         im.y = H - 52;
         box.addChild(im);
      }

      public function close():void
      {
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
