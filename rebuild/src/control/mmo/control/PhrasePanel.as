package mmo.control
{
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;

   /**
    * REBUILT 快捷语言 (the 发言 button). The phrases are the January 2013
    * client's own, from config.xml (message/phrases, read through
    * ConfigReader as the later control module's PhrasePanel reads them): a
    * column of topics; pointing at one with ▶ opens its phrases to the
    * right; a click says the phrase (SocketClient.sendPhrase, "[Phrase]").
    * The bar closes it when the mouse leaves it (ControlBar.togglePopup).
    */
   public class PhrasePanel extends Sprite
   {
      private static const ROW:int = 22;
      private static const W0:int = 92;
      private static const W1:int = 168;

      public var onPhrase:Function;
      private var columns:Array = [];
      private var tree:XMLList;

      public function PhrasePanel(phrases:XMLList)
      {
         super();
         tree = phrases;
         var n:int = phrases.p.length();
         // The pop-up's height is the first column's; sub-columns may grow upwards from it.
         graphics.beginFill(0, 0);
         graphics.drawRect(0, 0, W0, n * ROW + 8);
         graphics.endFill();
         showColumn(phrases.p, 0, 0);
         addEventListener(Event.REMOVED_FROM_STAGE, function(e:Event):void { if (e.target == e.currentTarget) hideFrom(1); });
      }

      /** Column `col` with `items`, its first row's top at y `top` (local). */
      private function showColumn(items:XMLList, col:int, top:Number, title:String = ""):void
      {
         hideFrom(col);
         var c:Sprite = new Sprite();
         c.name = title;
         var w:int = col == 0 ? W0 : W1;
         var n:int = items.length();
         var x:Number = col == 0 ? 0 : W0 + (col - 1) * W1 - 2;
         var h:Number = n * ROW + 8;
         // Keep it above the bar: a long column grows upwards.
         var y:Number = Math.min(top - 4, (tree.p.length() * ROW + 8) - h);
         BarSkin.panel(c.graphics, 0, 0, w, h, 12);
         for (var i:int = 0; i < n; i++)
         {
            var item:XML = items[i];
            c.addChild(row(item, col, w, 4 + i * ROW, y));
         }
         c.x = x;
         c.y = y;
         addChild(c);
         columns[col] = c;
      }

      private function row(item:XML, col:int, w:int, y:Number, colY:Number):Sprite
      {
         var r:Sprite = new Sprite();
         r.y = y;
         r.x = 4;
         var hasKids:Boolean = item.p.length() > 0;
         var text:String = String(item.@t);
         var t:TextField = BarSkin.label(text, 12, 0x14467A, 0xFFFFFFFF, false, "SimSun");
         t.x = 6;
         t.y = 2;
         r.addChild(t);
         var g:Graphics = r.graphics;
         var draw:Function = function(over:Boolean):void
         {
            g.clear();
            if (over)
            {
               g.lineStyle(1, 0xF0A000);
               BarSkin.vgrad(g, w - 8, ROW - 2, [0xFFF4C6, 0xFFD36A], 0);
            }
            else g.beginFill(0xFFFFFF, 0.01);
            g.drawRoundRect(0, 0, w - 8, ROW - 2, 8, 8);
            g.endFill();
            g.lineStyle();
            if (hasKids)
            {
               g.beginFill(0x2D7FC8);
               g.moveTo(w - 18, 6); g.lineTo(w - 12, 10); g.lineTo(w - 18, 14); g.lineTo(w - 18, 6);
               g.endFill();
            }
         };
         draw(false);
         r.buttonMode = true;
         r.mouseChildren = false;
         var open:Function = function():void
         {
            if (hasKids)
            {
               var shown:Sprite = columns[col + 1];
               if (shown == null || shown.name != text) showColumn(item.p, col + 1, colY + y, text);
            }
            else hideFrom(col + 1);
         };
         r.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void
         {
            draw(true);
            open();
         });
         r.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
         r.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (hasKids) { open(); return; }
            if (onPhrase != null) onPhrase(text);
         });
         return r;
      }

      private function hideFrom(col:int):void
      {
         for (var i:int = columns.length - 1; i >= col; i--)
         {
            var c:Sprite = columns[i];
            if (c != null && c.parent == this) removeChild(c);
            columns[i] = null;
         }
         columns.length = Math.min(columns.length, col);
      }
   }
}
