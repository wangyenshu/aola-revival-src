package mmo.common.utils.tips
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.text.TextFormatAlign;

   /**
    * What the big tips share (TipsManager.addComplexTips: a title over a text, in a border): the
    * later views' code without what the 2013 libraries lack (their buff lists, the "已拥有" count
    * kept in the hidden part, a scroller for very long texts).
    */
   public class BigTipsBase extends MovieClip
   {
      protected var html:Boolean;

      public function BigTipsBase()
      {
         super();
         stop();
      }

      protected function field(n:String):TextField
      {
         return getChildByName(n) as TextField;
      }

      public function setMessage(s:String):void
      {
         var f:TextFormat = new TextFormat();
         f.align = TextFormatAlign.LEFT;
         var t:TextField = field("txtmessagetitle");
         t.setTextFormat(f);
         if (html) t.htmlText = s;
         else t.text = s;
         t.selectable = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         t.x = 6;
         t.y = 5;
      }

      public function setMessageContent(s:String, minWidth:Number = 132):void
      {
         setTips(false);
         s = s == null ? "" : TipsMsgFilter.filterMsg(s);
         var owned:Boolean = !html && s.indexOf("已拥有：") >= 0;
         if (totalFrames > 1) gotoAndStop(owned ? 2 : 1);
         var f:TextFormat = new TextFormat();
         f.align = TextFormatAlign.LEFT;
         var title:TextField = field("txtmessagetitle");
         var num:TextField = field("txtNum");
         var text:TextField = field("txtmessagecontent");
         text.setTextFormat(f);
         text.multiline = true;
         text.selectable = false;
         text.width = title.width < minWidth ? minWidth : title.width;
         text.autoSize = TextFieldAutoSize.LEFT;
         if (num != null && owned)
         {
            var a:int = s.indexOf("已拥有："), b:int = s.indexOf("\n");
            num.text = s.substr(a, b < 0 ? s.length : b);
            s = b < 0 ? "" : s.substr(b + 1);
         }
         if (html) text.htmlText = s;
         else text.text = s;
         text.x = title.x;
         text.y = title.y + title.height + (html ? 0 : 5);
         for (var i:int = 0; i < 60 && text.textHeight > 400; i++)
         {
            text.width += 10;
            if (html) text.htmlText = text.htmlText;
            else text.text = text.text;
         }
         var extra:Number = num != null && owned ? num.height : 0;
         var border:DisplayObject = getChildByName("mcborder");
         if (border != null)
         {
            border.width = Math.max(title.width, text.width) + 8;
            border.height = title.height + text.height + 10 + extra;
         }
      }

      public function setTips(on:Boolean, frame:int = 1):void
      {
         var mc:MovieClip = getChildByName("mcTips") as MovieClip;
         if (mc == null) return;
         mc.visible = on;
         mc.gotoAndStop(frame);
         mc.x = field("txtmessagetitle").width + 5;
         mc.y = 2.5;
      }

      public function setTitleColor(c:uint):void
      {
         if (!html) field("txtmessagetitle").textColor = c;
      }

      public function setTextColor(c:uint):void
      {
         if (!html) field("txtmessagecontent").textColor = c;
      }

      public function dispose():void
      {
      }
   }
}
