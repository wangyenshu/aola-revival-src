package mmo.superevolution
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;

   /** 请选择你要超进化的亚比 (the 2015 module's ChoosePetPanel): the bag's 亚比, those of the races asked clickable. */
   public class ChoosePetPanel extends Sprite
   {
      public var pc0:PetContainer;
      public var pc1:PetContainer;
      public var pc2:PetContainer;
      public var pc3:PetContainer;
      public var pc4:PetContainer;
      public var pc5:PetContainer;
      public var btnClose:SimpleButton;
      public var txtTips:TextField;
      public var btnOK:SimpleButton;

      private var races:Array;
      private var callBack:Function;
      private var cur:PetContainer;

      public function ChoosePetPanel(races:Array, callBack:Function)
      {
         super();
         this.races = races;
         this.callBack = callBack;
         btnClose.addEventListener(MouseEvent.CLICK, closePanel);
         btnOK.addEventListener(MouseEvent.CLICK, onOk);
         initPet();
      }

      private function initPet():void
      {
         var any:Boolean = false;
         var pets:Array = (ServiceContainer.getService(IPetDataService) as IPetDataService).getMyPets() || [];
         for (var i:int = 0; i < pets.length && i < 6; i++)
         {
            var p:PetBriefInfo = pets[i];
            var c:PetContainer = getChildByName("pc" + i) as PetContainer;
            if (c == null) continue;
            c.setPetInfo(p);
            if (races.indexOf(p.raceId) == -1) DisplayUtil.applyGray(c);
            else
            {
               any = true;
               c.buttonMode = true;
               c.addEventListener(MouseEvent.CLICK, selectPet);
            }
         }
         txtTips.visible = !any;
      }

      private function selectPet(e:MouseEvent):void
      {
         if (cur != null) cur.setUnSelect();
         cur = e.currentTarget as PetContainer;
         cur.setSelect();
      }

      private function onOk(e:MouseEvent):void
      {
         if (cur == null)
         {
            NewDialog.showFailMessage("你还没有选择需要进化的亚比！");
            return;
         }
         callBack(cur.petInfo);
         closePanel(null);
      }

      public function showPanel():void
      {
         ModalDialogManager.getInstance().addModalDialog(this, AlignType.MIDDLE_CENTER);
      }

      private function closePanel(e:MouseEvent):void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
   }
}
