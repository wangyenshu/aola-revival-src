package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.filters.GlowFilter;
   import flash.text.TextField;

   /**
    * REBUILT. One button of the control bar: an icon over its name, as on the
    * December 2011 bar. Pointing at it lifts the icon a little with a glow.
    */
   public class BarButton extends Sprite
   {
      private var icon:DisplayObject;
      private var iconY:Number;

      /** icon centred at (0, iconY); the name centred under it at labelY (NaN: no name). */
      public function BarButton(name:String, icon:DisplayObject, text:String, iconY:Number = 0, labelY:Number = 20, onClick:Function = null)
      {
         super();
         this.name = name;
         this.icon = icon;
         this.iconY = iconY;
         icon.y = iconY;
         addChild(icon);
         if (text != null && text != "")
         {
            var t:TextField = BarSkin.label(text);
            t.x = Math.round(-t.width / 2);
            t.y = labelY;
            addChild(t);
         }
         buttonMode = true;
         useHandCursor = true;
         mouseChildren = false;
         addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void
         {
            icon.y = iconY - 2;
            icon.filters = [new GlowFilter(0xFFFFFF, 0.9, 8, 8, 2), new DropShadowFilter(1.5, 90, 0x0B3F70, 0.45, 3, 3, 1)];
         });
         addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void
         {
            icon.y = iconY;
            icon.filters = [new DropShadowFilter(1.5, 90, 0x0B3F70, 0.45, 3, 3, 1)];
         });
         addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (onClick != null) onClick(name);
         });
         addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent):void { e.stopPropagation(); });
      }
   }
}
