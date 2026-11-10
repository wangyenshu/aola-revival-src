package mmo.common.utils.tips
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;

   /** A one-line tip (TipsManager.addTips): its text in a border as wide and tall as it. */
   public class TipsView extends MovieClip
   {
      public var mcborder:MovieClip;
      public var txtmessage:TextField;

      public function TipsView()
      {
         super();
      }

      public function setMessage(s:String):void
      {
         var f:TextFormat = new TextFormat();
         f.align = TextFormatAlign.LEFT;
         txtmessage.setTextFormat(f);
         txtmessage.text = s;
         txtmessage.selectable = false;
         txtmessage.autoSize = TextFieldAutoSize.LEFT;
         mcborder.width = txtmessage.width + 8;
         mcborder.height = txtmessage.height + (txtmessage.numLines - 1) * 2;
      }

      public function setTitleColor(c:uint):void
      {
         txtmessage.textColor = c;
      }
   }
}
