package mmo.superevolution
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;

   /**
    * The 超进化 film (the 2015 module's EvolutionMovie): the 亚比 as it was, the light (mc), the
    * 亚比 it became from mc's frame 35; the close once the film is over.
    */
   public class EvolutionMovie extends MovieClip
   {
      public var btnClose:SimpleButton;
      public var iconContainer:MovieClip;
      public var mc:MovieClip;

      private var petIcon:PetIconContainer;
      private var petIcon2:PetIconContainer;
      private var originalViewId:int;
      private var evolutionViewId:int;

      public function EvolutionMovie(originalViewId:int, evolutionViewId:int)
      {
         super();
         this.originalViewId = originalViewId;
         this.evolutionViewId = evolutionViewId;
         mc.gotoAndStop(1);
      }

      public function show():void
      {
         ModalDialogManager.getInstance().addModalDialog(this);
         petIcon = new PetIconContainer(originalViewId, PetIconType.LARGE, false);
         petIcon.addEventListener(PetIconEvent.ON_ICON_LOADED, onFirst);
         petIcon.startLoad();
      }

      private function onFirst(e:PetIconEvent):void
      {
         petIcon.removeEventListener(PetIconEvent.ON_ICON_LOADED, onFirst);
         petIcon2 = new PetIconContainer(evolutionViewId, PetIconType.LARGE, false);
         petIcon2.addEventListener(PetIconEvent.ON_ICON_LOADED, onSecond);
         petIcon2.startLoad();
      }

      private function onSecond(e:PetIconEvent):void
      {
         petIcon2.removeEventListener(PetIconEvent.ON_ICON_LOADED, onSecond);
         playMovie();
      }

      private static function fit(icon:PetIconContainer):void
      {
         if (icon.width > icon.height) DisplayUtil.scaleDisplay(icon, 165, 0);
         else DisplayUtil.scaleDisplay(icon, 0, 190);
         DisplayUtil.middleDisplay(icon, 165, 190);
      }

      private function playMovie():void
      {
         iconContainer.addChild(petIcon);
         fit(petIcon);
         mc.addFrameScript(34, function():void
         {
            DisplayUtil.stopAndRemove(petIcon);
            iconContainer.addChild(petIcon2);
            fit(petIcon2);
            setChildIndex(mc, numChildren - 1);
         }, mc.totalFrames - 1, function():void
         {
            DisplayUtil.stop(mc);
            btnClose.addEventListener(MouseEvent.CLICK, onClose);
         });
         setChildIndex(mc, numChildren - 1);
         mc.gotoAndPlay(1);
      }

      private function onClose(e:MouseEvent):void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
