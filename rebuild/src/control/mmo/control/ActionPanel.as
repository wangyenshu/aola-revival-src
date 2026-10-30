package mmo.control
{
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;

   /**
    * REBUILT 动作 (the 动作 button): sit down facing one of the four slanting
    * directions. These are the avatar actions of the era skins (lddn ludn
    * rddn rudn in the skin's ActionInfo list, the buttons of the same names in
    * the later control module's ActionPanel); the choice goes to everyone in
    * the scene through ActionHelper (SocketClient.sendAction, "[Action]").
    */
   public class ActionPanel extends Sprite
   {
      public var onAction:Function;

      private static const DIRS:Array = [["ludn", -1, -1, 18, 30], ["rudn", 1, -1, 76, 30], ["lddn", -1, 1, 18, 72], ["rddn", 1, 1, 76, 72]];

      public function ActionPanel()
      {
         super();
         BarSkin.panel(graphics, 0, 0, 132, 118, 14);
         var t:TextField = BarSkin.label("坐下", 13, 0x14467A, 0xFFFFFFFF, true);
         t.x = 66 - t.width / 2;
         t.y = 6;
         addChild(t);
         for each (var d:Array in DIRS) addChild(button(d[0], d[1], d[2], d[3], d[4]));
      }

      private function button(code:String, dx:int, dy:int, x:Number, y:Number):Sprite
      {
         var b:Sprite = new Sprite();
         b.name = code;
         b.x = x;
         b.y = y;
         var g:Graphics = b.graphics;
         var draw:Function = function(over:Boolean):void
         {
            g.clear();
            g.lineStyle(1.2, over ? 0xF0A000 : 0x4E9DD3);
            BarSkin.vgrad(g, 38, 36, over ? [0xFFF6D2, 0xFFD36A] : [0xFFFFFF, 0xBFE5F8], 0);
            g.drawRoundRect(0, 0, 38, 36, 10, 10);
            g.endFill();
            g.lineStyle();
            // A little sitting figure looking the way of the arrow.
            BarSkin.ball(g, 19 + dx * 2, 11, 5.5, 0xFFD27A, 0xF09A2E, 0xC9761E, 1);
            g.lineStyle(1, 0x2A6FB0);
            BarSkin.vgrad(g, 14, 10, [0x6FC0F2, 0x2A7FCC], 16);
            g.drawRoundRect(12, 16, 14, 9, 6, 6);
            g.endFill();
            g.lineStyle(3, 0x2A7FCC);
            g.moveTo(19 + dx * 3, 24); g.lineTo(19 + dx * 9, 25);
            g.lineStyle();
            g.beginFill(0xE2561A);
            var ax:Number = 19 + dx * 13, ay:Number = 18 + dy * 11;
            g.moveTo(ax, ay);
            g.lineTo(ax - dx * 7, ay);
            g.lineTo(ax, ay - dy * 7);
            g.lineTo(ax, ay);
            g.endFill();
         };
         draw(false);
         b.buttonMode = true;
         b.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { draw(true); });
         b.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { draw(false); });
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (onAction != null) onAction(code);
         });
         return b;
      }
   }
}
