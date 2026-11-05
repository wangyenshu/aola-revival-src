package mmo.control
{
   import flash.display.CapsStyle;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.filters.DropShadowFilter;

   /**
    * REBUILT. The icons of the control bar, drawn after the December 2011
    * screenshot (the 2013 art was in the lost control/control.swf): 发言 an
    * orange ball with three dots on a cloud, 表情 a laughing yellow face,
    * 动作 a green figure, 射击 an orange ring with a blue sight, 信息卡 a card
    * with a figure, 好友 a handshake, 组队 three balls, 战队 a winged star badge,
    * 亚比 (the 背包) the 亚比球, 回家 the space capsule, 商城 a cart.
    * Each is centred on (0, 0) and about 36 px across.
    */
   public class BarIcons
   {
      public static function make(name:String):Sprite
      {
         var s:Sprite = new Sprite();
         var g:Graphics = s.graphics;
         switch (name)
         {
            case "phrase": phrase(g); break;
            case "face": face(g); break;
            case "action": action(s, g); break;
            case "shoot": shoot(g); break;
            case "card": card(g); break;
            case "friend": friend(s, g); break;
            case "team": team(g); break;
            case "squad": squad(g); break;
            case "pet": pet(g); break;
            case "home": home(g); break;
            case "mall": mall(g); break;
            case "toolbox": toolbox(g); break;
            case "sandbox": sandbox(g); break;
            case "petdic": petdic(g); break;
            case "items": items(g); break;
         }
         s.filters = [new DropShadowFilter(1.5, 90, 0x0B3F70, 0.45, 3, 3, 1)];
         return s;
      }

      private static function phrase(g:Graphics):void
      {
         BarSkin.cloud(g, 0, 13, 30);
         BarSkin.ball(g, 0, -3, 14, 0xFFB65C, 0xF0670A, 0xFFFFFF, 2);
         g.beginFill(0xFFFFFF);
         g.drawCircle(-6, -2, 2.6);
         g.drawCircle(0, -2, 2.6);
         g.drawCircle(6, -2, 2.6);
         g.endFill();
      }

      private static function face(g:Graphics):void
      {
         BarSkin.ball(g, 0, 0, 16, 0xFFF27C, 0xF4B70C, 0xD48C00, 1.5);
         g.beginFill(0xFF8A7A, 0.45);
         g.drawEllipse(-14, 1, 7, 4);
         g.drawEllipse(7, 1, 7, 4);
         g.endFill();
         g.lineStyle(2.2, 0x7A4300, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(-10, -4); g.curveTo(-6.5, -9.5, -3, -4);
         g.moveTo(3, -4); g.curveTo(6.5, -9.5, 10, -4);
         g.lineStyle(1.5, 0x7A4300);
         g.beginFill(0xA8401A);
         g.moveTo(-9, 1); g.curveTo(0, 15, 9, 1); g.lineTo(-9, 1);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF);
         g.moveTo(-8, 1.6); g.lineTo(8, 1.6); g.curveTo(0, 5.5, -8, 1.6);
         g.endFill();
         g.beginFill(0xFF7A7A);
         g.drawEllipse(-4, 6, 8, 4);
         g.endFill();
      }

      private static function action(s:Sprite, g:Graphics):void
      {
         g.lineStyle(5, 0x3FA83C, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(6, 2); g.lineTo(13, -8);
         g.moveTo(-6, 4); g.lineTo(-11, 11);
         g.moveTo(-3, 12); g.lineTo(-5, 17);
         g.moveTo(3, 12); g.lineTo(5, 17);
         g.lineStyle(1.2, 0x2A7F2A);
         BarSkin.vgrad(g, 16, 16, [0x9DE86C, 0x3FA83C], -2);
         g.drawEllipse(-8, -1, 16, 15);
         g.endFill();
         BarSkin.ball(g, 0, -9, 8.5, 0xB4F07E, 0x46B13E, 0x2A7F2A, 1.2);
         g.lineStyle(3, 0xFFB12B, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(-8, -10); g.curveTo(0, -22, 8, -10);
         g.lineStyle();
         g.beginFill(0xFFB12B);
         g.drawEllipse(-11, -12, 5, 7);
         g.drawEllipse(6, -12, 5, 7);
         g.endFill();
         g.beginFill(0x1F3A1F);
         g.drawCircle(-3, -9, 1.4);
         g.drawCircle(3, -9, 1.4);
         g.endFill();
      }

      private static function shoot(g:Graphics):void
      {
         BarSkin.ball(g, 0, 0, 16, 0xFFB24E, 0xDF5E0C, 0xFFFFFF, 2);
         g.lineStyle(1.2, 0x7EC3EC);
         BarSkin.vgrad(g, 24, 24, [0xFFFFFF, 0xD3EEFF], -12);
         g.drawCircle(0, 0, 11.5);
         g.endFill();
         g.lineStyle();
         g.beginFill(0x2B7FD2);
         g.moveTo(0, -10.5); g.lineTo(-3.4, -3.5); g.lineTo(3.4, -3.5); g.lineTo(0, -10.5);
         g.moveTo(0, 10.5); g.lineTo(-3.4, 3.5); g.lineTo(3.4, 3.5); g.lineTo(0, 10.5);
         g.moveTo(-10.5, 0); g.lineTo(-3.5, -3.4); g.lineTo(-3.5, 3.4); g.lineTo(-10.5, 0);
         g.moveTo(10.5, 0); g.lineTo(3.5, -3.4); g.lineTo(3.5, 3.4); g.lineTo(10.5, 0);
         g.endFill();
         g.lineStyle(1.6, 0x2B7FD2);
         g.drawCircle(0, 0, 2.4);
         g.lineStyle();
      }

      private static function card(g:Graphics):void
      {
         g.lineStyle(1.6, 0x2E7DBE);
         BarSkin.vgrad(g, 26, 32, [0xF1FAFF, 0x9AD3F3], -16);
         g.drawRoundRect(-13, -16, 26, 32, 8, 8);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.6);
         g.drawRoundRect(-10, -13, 20, 6, 4, 4);
         g.endFill();
         BarSkin.vgrad(g, 18, 12, [0xFFC24D, 0xEF8410], 4);
         g.moveTo(-9, 12); g.curveTo(-9, 3, 0, 3); g.curveTo(9, 3, 9, 12); g.lineTo(-9, 12);
         g.endFill();
         BarSkin.ball(g, 0, -3, 5.5, 0xFFCF66, 0xF08A12, 0xFFFFFF, 1);
      }

      private static function friend(s:Sprite, g:Graphics):void
      {
         var left:Shape = hand(0xFFD58E, 0xF2A23A);
         left.rotation = -28;
         left.x = -5;
         left.y = 4;
         s.addChild(left);
         var right:Shape = hand(0xFFE0A6, 0xF5AE48);
         right.rotation = 28;
         right.scaleX = -1;
         right.x = 5;
         right.y = 4;
         s.addChild(right);
         var bubble:Shape = new Shape();
         var b:Graphics = bubble.graphics;
         b.lineStyle(1, 0x8FB7D2);
         b.beginFill(0xFFFFFF);
         b.drawEllipse(-7, -5, 14, 10);
         b.endFill();
         b.lineStyle();
         b.beginFill(0x7D9BB0);
         b.drawCircle(-3.5, 0, 1.2);
         b.drawCircle(0, 0, 1.2);
         b.drawCircle(3.5, 0, 1.2);
         b.endFill();
         bubble.x = 10;
         bubble.y = -11;
         s.addChild(bubble);
      }

      private static function hand(top:uint, bottom:uint):Shape
      {
         var h:Shape = new Shape();
         var g:Graphics = h.graphics;
         g.lineStyle(1.2, 0xC9761E);
         BarSkin.vgrad(g, 22, 12, [top, bottom], -6);
         g.drawRoundRect(-12, -6, 22, 12, 10, 10);
         g.endFill();
         g.lineStyle(1, 0xC9761E, 0.7);
         g.moveTo(2, -5); g.lineTo(2, 5);
         g.moveTo(6, -5); g.lineTo(6, 5);
         g.lineStyle();
         return h;
      }

      private static function team(g:Graphics):void
      {
         BarSkin.ball(g, -7, -5, 8.5, 0x9BE865, 0x2E9E34, 0xFFFFFF, 1.2);
         BarSkin.ball(g, 7, -5, 8.5, 0x7ED0FF, 0x1C74CC, 0xFFFFFF, 1.2);
         BarSkin.ball(g, 0, 5, 10, 0xFFE76C, 0xF0A10C, 0xFFFFFF, 1.2);
      }

      private static function squad(g:Graphics):void
      {
         g.lineStyle(1.2, 0x3B8FC9);
         BarSkin.vgrad(g, 36, 20, [0xE6F7FF, 0x86CBEF], -10);
         g.moveTo(-6, -7); g.curveTo(-20, -14, -18, 2); g.curveTo(-12, 6, -6, 5); g.lineTo(-6, -7);
         g.moveTo(6, -7); g.curveTo(20, -14, 18, 2); g.curveTo(12, 6, 6, 5); g.lineTo(6, -7);
         g.endFill();
         g.lineStyle();
         BarSkin.ball(g, 0, 0, 11, 0x5DB2F0, 0x1A5DB0, 0xFFFFFF, 1.5);
         g.lineStyle(1, 0xB46F00);
         BarSkin.vgrad(g, 18, 18, [0xFFEC6A, 0xF5A600], -9);
         BarSkin.star(g, 0, 0.5, 8.5, 3.8);
         g.endFill();
         g.lineStyle();
      }

      /**
       * 亚比 (the bar's 背包, renamed): the 亚比球 of the item list (item/view32,
       * 普通亚比球) in the bar's style: a sprout on a glassy blue-white ball, its
       * orange crown, the brown arch and the yellow face with two eyes.
       */
      private static function pet(g:Graphics):void
      {
         // sprout
         g.lineStyle(2, 0x3FA83C, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(0, -12); g.lineTo(-1, -17);
         g.lineStyle(1, 0x2F8A2F);
         g.beginFill(0x8EDB3A);
         g.moveTo(-1, -17); g.curveTo(-7, -24, -13, -19); g.curveTo(-7, -14, -1, -17);
         g.moveTo(-1, -17); g.curveTo(6, -25, 12, -20); g.curveTo(6, -14, -1, -17);
         g.endFill();
         // glassy ball, a little wider at the bottom
         g.lineStyle(1.4, 0x2D6FC0);
         BarSkin.vgrad(g, 34, 30, [0xFFFFFF, 0xBFE6FF, 0x5DB5F2], -14);
         g.moveTo(0, -14); g.curveTo(15, -14, 16, 2); g.curveTo(17, 15, 0, 15); g.curveTo(-17, 15, -16, 2); g.curveTo(-15, -14, 0, -14);
         g.endFill();
         // orange crown
         g.lineStyle();
         BarSkin.vgrad(g, 26, 8, [0xFFE07A, 0xF59B1A], -14);
         g.moveTo(-12, -6); g.curveTo(-9, -14, 0, -14); g.curveTo(9, -14, 12, -6); g.curveTo(0, -10, -12, -6);
         g.endFill();
         // brown arch round the face
         g.lineStyle(3, 0x9A4E1E);
         g.moveTo(-9, 9); g.curveTo(-10, -8, 0, -8); g.curveTo(10, -8, 9, 9);
         // yellow face
         g.lineStyle(1, 0xC07A00);
         BarSkin.vgrad(g, 14, 14, [0xFFF27A, 0xF7C21C], -5);
         g.drawCircle(0, 2, 6.5);
         g.endFill();
         g.lineStyle();
         g.beginFill(0x1E2A5A);
         g.drawEllipse(-3.6, -1, 2.6, 4.2);
         g.drawEllipse(1, -1, 2.6, 4.2);
         g.endFill();
         g.beginFill(0xFFFFFF);
         g.drawCircle(-2.6, 0, 0.8);
         g.drawCircle(2, 0, 0.8);
         g.endFill();
         BarSkin.shine(g, -8, -9, 8, 4, 0.7);
      }

      private static function home(g:Graphics):void
      {
         g.lineStyle(1.2, 0x3B8FC9);
         BarSkin.vgrad(g, 34, 10, [0xC6F0FF, 0x4FA9E2], 6);
         g.drawEllipse(-17, 6, 34, 11);
         g.endFill();
         g.beginFill(0x5FB4E6);
         g.drawEllipse(-18, -9, 8, 11);
         g.drawEllipse(10, -9, 8, 11);
         g.endFill();
         g.lineStyle(1.4, 0x4A9AD4);
         BarSkin.vgrad(g, 28, 24, [0xFFFFFF, 0xC7E8FA], -14);
         g.moveTo(-13, 10); g.curveTo(-14, -15, 0, -15); g.curveTo(14, -15, 13, 10); g.lineTo(-13, 10);
         g.endFill();
         g.lineStyle(1.2, 0x2E8A2E);
         BarSkin.vgrad(g, 18, 11, [0xB8F574, 0x3FAE36], -6);
         g.drawEllipse(-9, -6, 18, 11);
         g.endFill();
         g.lineStyle();
         BarSkin.shine(g, -1, -3.5, 12, 4, 0.8);
         g.lineStyle(1.5, 0x4A9AD4);
         g.moveTo(0, -15); g.lineTo(0, -19);
         g.lineStyle();
         g.beginFill(0xFFB12B);
         g.drawCircle(0, -20, 2.2);
         g.endFill();
      }

      /** The revival's 物品 (not of 2013): a satchel, in the bar's style. */
      private static function items(g:Graphics):void
      {
         g.lineStyle(1.5, 0x8A4A00);
         BarSkin.vgrad(g, 28, 22, [0xFFD06A, 0xE8781A], -8);
         g.drawRoundRect(-14, -8, 28, 22, 10, 10);
         g.endFill();
         // the strap and the flap
         g.lineStyle(2.5, 0xB55A00);
         g.moveTo(-9, -8); g.curveTo(0, -20, 9, -8);
         g.lineStyle(1.5, 0x8A4A00);
         BarSkin.vgrad(g, 28, 11, [0xFFE7A8, 0xF7A93A], -8);
         g.moveTo(-14, -3); g.curveTo(-14, -8, -9, -8); g.lineTo(9, -8); g.curveTo(14, -8, 14, -3);
         g.lineTo(14, 1); g.lineTo(-14, 1); g.lineTo(-14, -3);
         g.endFill();
         g.lineStyle(1.2, 0x8A4A00);
         g.beginFill(0x7FD0FF);
         g.drawCircle(0, 2, 3.2);
         g.endFill();
         g.lineStyle();
         BarSkin.shine(g, -6, -5, 10, 4, 0.6);
      }

      /** The revival's 工具箱 (not of 2013): a chest with a star, in the bar's style. */
      private static function toolbox(g:Graphics):void
      {
         BarSkin.ball(g, 0, 0, 17, 0x7FD0FF, 0x1F7FD0, 0xFFFFFF, 2);
         g.lineStyle(1.5, 0x8A4A00);
         BarSkin.vgrad(g, 22, 13, [0xFFD57A, 0xF0901E], -2);
         g.drawRoundRect(-11, -2, 22, 13, 4, 4);
         g.endFill();
         BarSkin.vgrad(g, 24, 8, [0xFFE7A8, 0xF7A93A], -9);
         g.drawRoundRect(-12, -9, 24, 8, 6, 6);
         g.endFill();
         g.lineStyle(1.2, 0x8A4A00);
         g.beginFill(0xFFF3C8);
         g.drawRect(-2.5, -3, 5, 5);
         g.endFill();
         g.lineStyle(1, 0xFFFFFF);
         g.beginFill(0xFFF27A);
         BarSkin.star(g, 9, -12, 6, 2.6);
         g.endFill();
         g.lineStyle();
         BarSkin.shine(g, -5, -10, 12, 5, 0.6);
      }

      /** The 图鉴: an open book with a paw print, on a green ball. */
      private static function petdic(g:Graphics):void
      {
         BarSkin.ball(g, 0, 0, 17, 0x9BE86A, 0x2F9E3A, 0xFFFFFF, 2);
         g.lineStyle(1.5, 0x1F5E2A);
         g.beginFill(0xFFFDF2);
         g.moveTo(0, -6); g.curveTo(-6, -10, -13, -8); g.lineTo(-13, 9); g.curveTo(-6, 7, 0, 11);
         g.curveTo(6, 7, 13, 9); g.lineTo(13, -8); g.curveTo(6, -10, 0, -6);
         g.endFill();
         g.moveTo(0, -6); g.lineTo(0, 11);
         g.lineStyle();
         g.beginFill(0xE0702A);
         g.drawEllipse(-9.5, 1, 6, 5);
         g.drawCircle(-10.5, -2.5, 1.5);
         g.drawCircle(-8, -4, 1.5);
         g.drawCircle(-5, -4, 1.5);
         g.drawCircle(-3.5, -1.5, 1.4);
         g.endFill();
         g.lineStyle(1, 0x7FA88A);
         g.moveTo(3, -2); g.lineTo(10, -3);
         g.moveTo(3, 2); g.lineTo(10, 1.5);
         g.moveTo(3, 6); g.lineTo(9, 5.5);
         g.lineStyle();
         BarSkin.shine(g, -6, -11, 12, 5, 0.5);
      }

      /** The 沙盒: a sand castle with its flag and a little spade, on a sand-coloured ball. */
      private static function sandbox(g:Graphics):void
      {
         BarSkin.ball(g, 0, 0, 17, 0xFFE7A0, 0xE79A2E, 0xFFFFFF, 2);
         // the castle
         g.lineStyle(1.5, 0x8A4A00);
         BarSkin.vgrad(g, 20, 16, [0xFFF0C0, 0xF2B44E], -2);
         g.moveTo(-10, 12); g.lineTo(-10, -2); g.lineTo(-7, -2); g.lineTo(-7, 1); g.lineTo(-3, 1); g.lineTo(-3, -2);
         g.lineTo(3, -2); g.lineTo(3, 1); g.lineTo(7, 1); g.lineTo(7, -2); g.lineTo(10, -2); g.lineTo(10, 12); g.lineTo(-10, 12);
         g.endFill();
         g.beginFill(0x8A4A00);
         g.drawRoundRect(-2.5, 5, 5, 7, 4, 4);
         g.endFill();
         // the flag
         g.lineStyle(1.3, 0x8A4A00);
         g.moveTo(0, -2); g.lineTo(0, -14);
         g.lineStyle(1, 0xB22A2A);
         g.beginFill(0xFF5A4A);
         g.moveTo(0, -14); g.lineTo(9, -11); g.lineTo(0, -8); g.lineTo(0, -14);
         g.endFill();
         // the spade
         g.lineStyle(2, 0x2E86D6, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(-15, -12); g.lineTo(-9, -4);
         g.lineStyle(1, 0x1F5FA0);
         g.beginFill(0x6CC0F5);
         g.drawEllipse(-11, -6, 6, 8);
         g.endFill();
         g.lineStyle();
         BarSkin.shine(g, -4, -11, 10, 4, 0.55);
      }

      private static function mall(g:Graphics):void
      {
         g.lineStyle(2.5, 0xB55A00, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(-15, -10); g.lineTo(-20, -16);
         g.lineStyle(1.5, 0xB55A00);
         BarSkin.vgrad(g, 30, 18, [0xFFC45A, 0xF07812], -10);
         g.moveTo(-15, -10); g.lineTo(15, -10); g.lineTo(11, 7); g.lineTo(-11, 7); g.lineTo(-15, -10);
         g.endFill();
         g.lineStyle(1, 0xFFFFFF, 0.65);
         g.moveTo(-14, -4); g.lineTo(14, -4);
         g.moveTo(-12, 2); g.lineTo(12, 2);
         g.moveTo(-5, -10); g.lineTo(-4, 7);
         g.moveTo(5, -10); g.lineTo(4, 7);
         g.lineStyle(1.2, 0x333333);
         g.beginFill(0x5A5A5A);
         g.drawCircle(-7, 11, 3);
         g.drawCircle(8, 11, 3);
         g.endFill();
         g.lineStyle();
      }
   }
}
