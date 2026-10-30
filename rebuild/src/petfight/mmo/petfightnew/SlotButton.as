package mmo.petfightnew
{
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormatAlign;

   /**
    * REBUILT. A square in the 捕捉 / 道具 pages: the item's own picture
    * (item/view<id>, as the 2013 ItemViewCreator loads it) and how many are
    * left in the corner, as in the December 2011 screenshots. Pointing at it
    * shows name and use.
    */
   public class SlotButton extends Sprite
   {
      public static const S:int = 54;

      private var face:Shape = new Shape();
      private var over:Boolean;
      private var _enabled:Boolean = true;
      public var data:Object;

      public function SlotButton(itemId:int, count:int, data:Object)
      {
         super();
         this.data = data;
         addChild(face);
         if (itemId > 0)
         {
            var pic:Sprite = new Sprite();
            pic.x = S / 2;
            pic.y = S / 2 - 2;
            addChild(pic);
            FightSkin.itemIcon(pic, itemId, S - 12);
         }
         if (data != null)
         {
            var n:TextField = FightSkin.label(String(count), 11, 0x163A5C, 0xFFFFFF, true, TextFormatAlign.RIGHT, "Arial");
            n.x = S - 4 - n.width;
            n.y = S - 16;
            addChild(n);
         }
         buttonMode = data != null;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { over = true; draw(); });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { over = false; draw(); });
         draw();
      }

      public function set enabled(v:Boolean):void
      {
         _enabled = v;
         mouseEnabled = v;
         buttonMode = v && data != null;
         alpha = v ? 1 : 0.6;
         draw();
      }

      private function draw():void
      {
         var g:Graphics = face.graphics;
         g.clear();
         g.lineStyle(2, over && _enabled && data ? 0xF2A400 : 0x7CB9D8);
         FightSkin.vgrad(g, S, S, 0xF7FFF2, 0xD9F2E2);
         g.drawRoundRect(0, 0, S, S, 10, 10);
         g.endFill();
      }
   }
}
