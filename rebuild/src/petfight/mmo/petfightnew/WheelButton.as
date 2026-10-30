package mmo.petfightnew
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormatAlign;

   /**
    * REBUILT. One bubble of the command wheel (道具 捕捉 战斗 亚比 逃跑): light
    * blue glass, orange (战斗) or green (the others) while its page is open.
    */
   public class WheelButton extends Sprite
   {
      private var face:Shape = new Shape();
      private var r:int;
      private var onColor:Array;
      private var _selected:Boolean;
      private var _enabled:Boolean = true;
      private var over:Boolean;

      public function WheelButton(name:String, text:String, r:int, orange:Boolean)
      {
         super();
         this.name = name;
         this.r = r;
         onColor = orange ? [0xFFE08A, 0xF07A12, 0xB24A00] : [0xD8F7A8, 0x4DB51E, 0x2E7A10];
         addChild(face);
         var t:TextField = FightSkin.label(text, r >= 26 ? 17 : 14, 0xFFFFFF, FightSkin.TEXT_EDGE, true, TextFormatAlign.CENTER);
         t.x = -t.width / 2;
         t.y = -t.height / 2;
         addChild(t);
         buttonMode = true;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { over = true; draw(); });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { over = false; draw(); });
         draw();
      }

      public function set selected(v:Boolean):void
      {
         _selected = v;
         draw();
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
         alpha = v ? 1 : 0.55;
         draw();
      }

      private function draw():void
      {
         if (_selected) FightSkin.bubble(face.graphics, r, onColor[0], onColor[1], onColor[2]);
         else if (over && _enabled) FightSkin.bubble(face.graphics, r, 0xF2FCFF, 0x7CCBF2, FightSkin.BLUE_EDGE);
         else FightSkin.bubble(face.graphics, r, 0xDDF4FF, 0x4FA8DE, FightSkin.BLUE_EDGE);
      }
   }
}
