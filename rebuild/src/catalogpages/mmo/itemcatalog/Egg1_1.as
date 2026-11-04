package mmo.itemcatalog
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;

   /**
    * REBUILT first page of the 收费亚比蛋商品册 (catalog201006, catalog/egg1): the 亚比蛋 of the
    * 2013 PetEggData that have a price, six to a page, on the art of the page's later copy
    * (2016). The January 2013 page is lost, and the later page's code reads a later egg list
    * of later libraries. Its 本周热卖榜 (eggs of 2016) and 亚比蛋孵化说明 are put away.
    */
   public class Egg1_1 extends Sprite
   {
      /** The eggs, the latest of PetEggData first. */
      public static const EGGS:Array = [112, 482, 1337, 1340, 1277, 1275, 1260, 1237, 1184, 1311, 1264, 1256, 1226, 1239, 858, 856,
         1160, 873, 392, 337, 409, 1143, 178, 285, 817, 1393, 770, 1321, 1319, 1292, 1266, 1258, 1211, 839, 755, 786, 705, 1188,
         947, 890, 602, 109, 864, 13, 515, 713, 680, 520, 416, 315, 663, 637, 473, 470, 467, 425, 276, 193, 106, 64, 37, 79, 82,
         73, 127, 130, 85, 97, 100, 103, 94, 91, 88];
      private static const PER_PAGE:int = 6;
      /** Page numbers shown at once (the art's mcPage0 … mcPage6). */
      private static const GROUP:int = 7;
      private static const SPOTS:Array = [new Point(212, 275), new Point(391, 274), new Point(569, 271), new Point(214, 460), new Point(391, 459), new Point(569, 460)];

      public var btnPageNext:SimpleButton;
      public var btnPagePrev:SimpleButton;
      public var btnGroupNext:SimpleButton;
      public var btnGroupPrev:SimpleButton;
      public var btnIntroduce:SimpleButton;
      public var hotlist:MovieClip;
      public var mcPage0:MovieClip;
      public var mcPage1:MovieClip;
      public var mcPage2:MovieClip;
      public var mcPage3:MovieClip;
      public var mcPage4:MovieClip;
      public var mcPage5:MovieClip;
      public var mcPage6:MovieClip;

      private var current:int;
      private var group:int;
      private var total:int;
      private var panels:Array = [];

      public function Egg1_1()
      {
         super();
         total = Math.ceil(EGGS.length / PER_PAGE);
         if (hotlist) hotlist.visible = false;
         if (btnIntroduce) btnIntroduce.visible = false;
         addEventListener(MouseEvent.CLICK, onClick);
         show(1);
      }

      private function onClick(e:MouseEvent):void
      {
         var name:String = e.target is Object && e.target.name ? String(e.target.name) : "";
         if (name == "btnPagePrev") show(current - 1);
         else if (name == "btnPageNext") show(current + 1);
         else if (name == "btnGroupPrev") showGroup(group - 1);
         else if (name == "btnGroupNext") showGroup(group + 1);
         else if (name == "btnPageJump" && e.target.parent != null) show((group - 1) * GROUP + int(String(e.target.parent.name).substr(6)) + 1);
      }

      private function show(p:int):void
      {
         if (p < 1 || p > total) return;
         current = p;
         for each (var old:Sprite in panels) removeChild(old);
         panels = [];
         for (var i:int = 0; i < PER_PAGE; i++)
         {
            var k:int = (current - 1) * PER_PAGE + i;
            if (k >= EGGS.length) break;
            var panel:PetEggPanel = new PetEggPanel(int(EGGS[k]));
            panel.x = Point(SPOTS[i]).x;
            panel.y = Point(SPOTS[i]).y;
            addChild(panel);
            panels.push(panel);
         }
         enable(btnPagePrev, current > 1);
         enable(btnPageNext, current < total);
         showGroup(Math.ceil(current / GROUP));
      }

      private function showGroup(g:int):void
      {
         var groups:int = Math.ceil(total / GROUP);
         if (g < 1 || g > groups) return;
         group = g;
         enable(btnGroupPrev, group > 1);
         enable(btnGroupNext, group < groups);
         for (var i:int = 0; i < GROUP; i++)
         {
            var mc:MovieClip = getChildByName("mcPage" + i) as MovieClip;
            if (mc == null) continue;
            var n:int = (group - 1) * GROUP + i + 1;
            mc.visible = n <= total;
            mc.gotoAndStop(n == current ? 2 : 1);
            var t:TextField = mc.getChildByName("txtPage") as TextField;
            if (t != null)
            {
               t.text = String(n);
               t.mouseEnabled = false;
            }
         }
      }

      private static function enable(b:SimpleButton, on:Boolean):void
      {
         if (b == null) return;
         b.mouseEnabled = on;
         b.alpha = on ? 1 : 0.4;
      }
   }
}
