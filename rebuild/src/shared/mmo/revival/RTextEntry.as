package mmo.revival
{
   import flash.events.MouseEvent;
   import flash.external.ExternalInterface;
   import flash.text.TextField;
   import flash.utils.getTimer;

   /**
    * REVIVAL: Chinese words for an input field through the browser. The Flash
    * player (Ruffle) does not take an input method's composed characters, so
    * typing 十字大道 left the raw letters (chchuan…) in the field. A click on
    * the field opens the browser's own text box (window.prompt, where the
    * input method works) with what is in the field; its words go into the
    * field and onDone, if given, runs as Enter would. Typing straight into the
    * field still works.
    */
   public class RTextEntry
   {
      public static function attach(t:TextField, title:String, onDone:Function = null):void
      {
         var last:int = 0;
         t.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            if (getTimer() - last < 600) return;
            var got:* = null;
            try
            {
               if (!ExternalInterface.available) return;
               got = ExternalInterface.call("prompt", title, t.text);
            }
            catch (err:Error) { return; }
            last = getTimer();
            if (got == null) return;
            t.text = String(got).substr(0, t.maxChars > 0 ? t.maxChars : 200);
            if (t.stage) t.stage.focus = null;
            if (onDone != null) onDone();
         });
      }
   }
}
