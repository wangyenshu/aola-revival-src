package mmo.pet
{
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;

   /**
    * REVIVAL: the template of the large picture tools/peticon_fill.py gives a 亚比 with no art
    * anywhere (鲁阿鲁 119, 源第一态 1929, 天启英灵 2295: neither a peticon file nor a battle
    * sprite in the era files or on the game's server): a dark figure with a "?", not another
    * 亚比's picture. The tool copies this class's bytecode into the new file under the name
    * mmo.pet.peticon<id>_L.
    */
   public dynamic class peticon777777_L extends MovieClip
   {
      public function peticon777777_L()
      {
         super();
         var k:Number = 1.6;
         var s:Shape = new Shape();
         // A figure: a body and a head, feet 15 above the origin.
         s.graphics.lineStyle(2 / k, 0x9FB8D8, 0.9);
         s.graphics.beginFill(0x34466A, 0.92);
         s.graphics.drawEllipse(-20, -40, 40, 34);
         s.graphics.endFill();
         s.graphics.beginFill(0x34466A, 0.92);
         s.graphics.drawCircle(0, -48, 13);
         s.graphics.endFill();
         s.scaleX = s.scaleY = k;
         s.y = -15;
         addChild(s);
         var t:TextField = new TextField();
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.CENTER;
         t.defaultTextFormat = new TextFormat("Arial", Math.round(26 * k), 0xFFFFFF, true);
         t.text = "?";
         t.x = -t.width / 2;
         t.y = (-31 * k) + -15 - t.height / 2;
         addChild(t);
      }
   }
}
