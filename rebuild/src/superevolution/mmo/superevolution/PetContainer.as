package mmo.superevolution
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.revival.RIcon;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;

   /** One 亚比 of the bag in ChoosePetPanel (the 2015 module's PetContainer). */
   public class PetContainer extends Sprite
   {
      public var mcSelect:MovieClip;
      public var txtInfo:TextField;

      private var _petInfo:PetBriefInfo;

      public function PetContainer()
      {
         super();
         DisplayUtil.applyGray(this);
         txtInfo.mouseEnabled = false;
         txtInfo.text = "";
         setUnSelect();
      }

      public function setPetInfo(p:PetBriefInfo):void
      {
         _petInfo = p;
         DisplayUtil.clearFilters(this);
         var icon:PetIconContainer = RIcon.container(p.viewId, PetIconType.LARGE, false);
         icon.addEventListener(PetIconEvent.ON_ICON_LOADED, onLoadIcon);
         icon.startLoad();
         txtInfo.text = p.name + "\n" + p.level + "级";
      }

      public function get petInfo():PetBriefInfo
      {
         return _petInfo;
      }

      public function setSelect():void
      {
         mcSelect.visible = true;
      }

      public function setUnSelect():void
      {
         mcSelect.visible = false;
      }

      private function onLoadIcon(e:PetIconEvent):void
      {
         var icon:PetIconContainer = e.currentTarget as PetIconContainer;
         icon.removeEventListener(PetIconEvent.ON_ICON_LOADED, onLoadIcon);
         icon.mouseEnabled = icon.mouseChildren = false;
         addChild(icon);
         DisplayUtil.stop(icon);
         DisplayUtil.scaleDisplay(icon, 45, 45);
         DisplayUtil.middleDisplay(icon, 53, 53);
      }
   }
}
