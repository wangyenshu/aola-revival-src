package mmo.petfightnew
{
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormatAlign;

   /**
    * REBUILT. A 亚比 of the bag in the 亚比 page: its icon, name, level and HP.
    * The one fighting and the fallen ones cannot be picked.
    */
   public class PetRow extends Sprite
   {
      public static const W:int = 132;
      public static const H:int = 44;

      private var face:Shape = new Shape();
      private var over:Boolean;
      private var _enabled:Boolean = true;
      private var current:Boolean;
      public var data:Object;

      public function PetRow(view:Object, current:Boolean)
      {
         super();
         data = view;
         this.current = current;
         addChild(face);
         var icon:Sprite = new Sprite();
         icon.x = 21;
         icon.y = H / 2;
         addChild(icon);
         FightSkin.petIcon(icon, int(view.r), 34);
         var hp:int = int(view.c0);
         var s0:Array = String(view.s0 || "1#0").split("#");
         var max:int = Math.max(1, int(s0[0]) + int(s0[1]));
         var n:TextField = FightSkin.label(String(view.nick || view.nm), 12, 0xFFFFFF, FightSkin.TEXT_EDGE, true);
         n.x = 42;
         n.y = 2;
         addChild(n);
         var lv:TextField = FightSkin.label("Lv." + view.lv, 11, 0xFFF2A0, FightSkin.TEXT_EDGE, true, TextFormatAlign.RIGHT, "Arial");
         lv.x = W - 6 - lv.width;
         lv.y = 3;
         addChild(lv);
         var bar:Shape = new Shape();
         FightSkin.hpBar(bar.graphics, 84, 9, hp / max);
         bar.x = 42;
         bar.y = 21;
         addChild(bar);
         var t:TextField = FightSkin.label(hp + "/" + max, 10, 0xFFFFFF, FightSkin.TEXT_EDGE, false, TextFormatAlign.LEFT, "Arial");
         t.x = 44;
         t.y = 29;
         addChild(t);
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { over = true; draw(); });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { over = false; draw(); });
         draw();
      }

      public function set enabled(v:Boolean):void
      {
         _enabled = v;
         mouseEnabled = v;
         buttonMode = v;
         alpha = v || current ? 1 : 0.55;
         draw();
      }

      private function draw():void
      {
         var g:Graphics = face.graphics;
         g.clear();
         var top:Array = current ? [0xFFE08A, 0xF09A22] : (over && _enabled ? [0x9FE0FF, 0x3B9BD8] : [0x7CCBF2, 0x2C7FC0]);
         g.lineStyle(1.5, current ? 0xB25A00 : 0x1E5F98);
         FightSkin.vgrad(g, W, H, top[0], top[1]);
         g.drawRoundRect(0, 0, W, H, 12, 12);
         g.endFill();
         g.lineStyle();
         g.beginFill(0xFFFFFF, 0.3);
         g.drawRoundRect(3, 2, W - 6, H / 2 - 4, 10, 10);
         g.endFill();
      }
   }
}
