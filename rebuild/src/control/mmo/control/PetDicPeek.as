package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.utils.getQualifiedClassName;
   import mmo.revival.RLog;

   /**
    * REVIVAL. The 图鉴 (the later pet/petdictionary) opens a 亚比's page only for the 亚比 met or
    * owned; a grey one does nothing when clicked. Here a grey one opens its page too: a click on
    * a PetIcon the panel greyed (its alpha 0.6, PetIcon.setUnknow) shows IntroPanel.instance for
    * its raceId, as the panel's PetIconHandler does for the others. The hand shows over it.
    */
   public class PetDicPeek
   {
      private static const ICON:String = "mmo.pet.petdictionary.view.imp::PetIcon";
      private static const INTRO:String = "mmo.pet.petdictionary.view.imp.IntroPanel";
      private static var installed:Boolean;

      /** On the container of the game's layers (LayerManager.stage): clicks in any panel come by it. */
      public static function install(root:DisplayObjectContainer):void
      {
         if (installed || root == null) return;
         installed = true;
         root.addEventListener(MouseEvent.CLICK, onClick, true);
         root.addEventListener(MouseEvent.MOUSE_OVER, onOver, true);
      }

      /** The grey PetIcon under the mouse, if any. */
      private static function greyIcon(d:DisplayObject):Sprite
      {
         for (var i:int = 0; d != null && i < 6; i++, d = d.parent)
         {
            if (getQualifiedClassName(d) != ICON) continue;
            var s:Sprite = d as Sprite;
            return s != null && s.alpha < 0.99 && int(Object(s).raceId) > 0 ? s : null;
         }
         return null;
      }

      private static function onOver(e:MouseEvent):void
      {
         var s:Sprite = greyIcon(e.target as DisplayObject);
         if (s != null) s.buttonMode = true;
      }

      private static function onClick(e:MouseEvent):void
      {
         var s:Sprite = greyIcon(e.target as DisplayObject);
         if (s == null) return;
         try
         {
            var dom:ApplicationDomain = ApplicationDomain.currentDomain;
            if (!dom.hasDefinition(INTRO)) return;
            var C:Object = dom.getDefinition(INTRO);
            if (C.instance == null) return;
            // Its 获取方式 tip goes, as when the mouse leaves it.
            s.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
            C.instance.show(int(Object(s).raceId));
         }
         catch (err:Error) { RLog.error("图鉴 page", err); }
      }
   }
}
