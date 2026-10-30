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
    * 背包 a yellow sprout 亚比 on a cloud, 回家 the space capsule, 商城 a cart.
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

      private static function pet(g:Graphics):void
      {
         BarSkin.cloud(g, 0, 13, 32);
         g.lineStyle(2, 0x3FA83C, 1, false, "normal", CapsStyle.ROUND);
         g.moveTo(0, -11); g.lineTo(0, -16);
         g.lineStyle(1, 0x2F8A2F);
         g.beginFill(0x6FD24A);
         g.moveTo(0, -16); g.curveTo(-6, -23, -11, -17); g.curveTo(-6, -13, 0, -16);
         g.moveTo(0, -16); g.curveTo(6, -24, 11, -18); g.curveTo(6, -13, 0, -16);
         g.endFill();
         BarSkin.ball(g, 0, 0, 12, 0xFFE76A, 0xF2A90E, 0xD08A00, 1.4);
         g.lineStyle(1, 0x6B4A00);
         g.beginFill(0xFFFFFF);
         g.drawEllipse(-8, -5, 7, 8);
         g.drawEllipse(1, -5, 7, 8);
         g.endFill();
         g.lineStyle();
         g.beginFill(0x2A2A2A);
         g.drawCircle(-4, -0.5, 2.2);
         g.drawCircle(4.5, -0.5, 2.2);
         g.endFill();
         g.lineStyle(1.2, 0x8A4A00);
         g.moveTo(-3, 6); g.curveTo(0, 8.5, 3, 6);
         g.lineStyle();
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
