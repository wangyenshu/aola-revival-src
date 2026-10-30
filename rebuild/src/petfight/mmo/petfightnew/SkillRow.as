package mmo.petfightnew
{
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormatAlign;

   /**
    * REBUILT. A skill in the 战斗 page, as the December 2011 screenshots show
    * it: a green plate with the attribute icon and the name, and a dark band
    * with "威力: 150  PP 10/10". Yellow under the mouse; grey without PP.
    */
   public class SkillRow extends Sprite
   {
      public static const W:int = 132;
      public static const H:int = 42;

      private var face:Shape = new Shape();
      private var icon:Sprite = new Sprite();
      private var nameText:TextField;
      private var info:TextField;
      private var over:Boolean;
      private var _enabled:Boolean = true;
      public var data:Object;

      public function SkillRow(skill:Object)
      {
         super();
         data = skill;
         addChild(face);
         icon.x = 15;
         icon.y = 13;
         addChild(icon);
         nameText = FightSkin.label(skill ? String(skill.name) : "", 13, 0xFFFFFF, 0x245E14, true, TextFormatAlign.RIGHT);
         nameText.x = W - 6 - nameText.width;
         nameText.y = 3;
         addChild(nameText);
         var pp:Array = skill ? String(skill.pp || "0/0").split("/") : ["", ""];
         var power:int = skill ? int(skill.pw) : 0;
         info = FightSkin.label(skill ? "威力:" + (power > 0 ? power : "—") + "  PP " + pp[0] + "/" + pp[1] : "", 11, 0xFFFFFF, 0x173F0C, false, TextFormatAlign.LEFT, "宋体");
         info.x = 6;
         info.y = 25;
         addChild(info);
         if (skill) FightSkin.attributeIcon(icon, int(skill.t), 22);
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { over = true; draw(); });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { over = false; draw(); });
         draw();
      }

      public function get pp():int
      {
         return data ? int(String(data.pp || "0/0").split("/")[0]) : 0;
      }

      public function get enabled():Boolean
      {
         return _enabled;
      }

      public function set enabled(v:Boolean):void
      {
         _enabled = v;
         mouseEnabled = v;
         buttonMode = v;
         draw();
      }

      private function draw():void
      {
         var g:Graphics = face.graphics;
         g.clear();
         var usable:Boolean = data != null && pp > 0;
         var top:Array = !usable ? [0xD9DDE0, 0x9AA3AA] : (over && _enabled ? [0xFFF1A0, 0xF2C230] : [0xB4E888, 0x58AE2E]);
         var edge:uint = !usable ? 0x7A848C : (over && _enabled ? 0xB88A10 : 0x3B8A22);
         var band:uint = !usable ? 0x6E777E : (over && _enabled ? 0xA87A08 : 0x2E7A1E);
         g.lineStyle(1.5, edge);
         FightSkin.vgrad(g, W, H, top[0], top[1]);
         g.drawRoundRect(0, 0, W, H, 10, 10);
         g.endFill();
         g.lineStyle();
         g.beginFill(band);
         g.drawRoundRectComplex(2, 24, W - 4, H - 26, 0, 0, 7, 7);
         g.endFill();
         g.beginFill(0xFFFFFF, 0.35);
         g.drawRoundRect(3, 2, W - 6, 10, 8, 8);
         g.endFill();
         alpha = _enabled || !usable ? 1 : 0.75;
      }
   }
}
