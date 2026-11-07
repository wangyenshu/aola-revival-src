package mmo.pet.petride
{
   import flash.display.*;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.ride.IRideService;
   
   public class PetRidePanel extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var btnOk:SimpleButton;
      
      private var petDataService:IPetDataService;
      
      private var myPets:Array;
      
      private var petCardContainerAry:Array = new Array();
      
      private var selectPetinfo:PetBriefInfo;
      
      private var rideService:IRideService;
      
      private var curSelect:int = -1;
      
      public var dragMC:MovieClip;
      
      public function PetRidePanel()
      {
         super();
         this.rideService = ServiceContainer.getService(IRideService) as IRideService;
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.myPets = this.petDataService.getMyPets();
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         SimpleButton(this.btnOk).addEventListener(MouseEvent.CLICK,this.onClickOk);
         this.addPetCards();
      }
      
      private function addPetCards() : void
      {
         var _loc4_:PetRideTranningPetBriefCard = null;
         if(this.myPets.length == 0)
         {
            return;
         }
         var _loc1_:Array = [72.55,221.55,72.55,221.55,72.55,221.55];
         var _loc2_:Array = [100.5,100.5,190,190,279.5,279.5];
         var _loc3_:int = 0;
         while(_loc3_ < this.myPets.length)
         {
            _loc4_ = new PetRideTranningPetBriefCard(this.myPets[_loc3_]);
            _loc4_.x = _loc1_[_loc3_];
            _loc4_.y = _loc2_[_loc3_];
            _loc4_.name = "ps" + _loc3_;
            _loc4_.addEventListener(MouseEvent.CLICK,this.onClickPet);
            this.petCardContainerAry.push(_loc4_);
            this.addChild(_loc4_);
            _loc3_++;
         }
      }
      
      private function onClickPet(param1:MouseEvent) : void
      {
         var _loc2_:int = int((param1.currentTarget as DisplayObject).name.charAt(2));
         this.showPetByIndex(_loc2_);
      }
      
      private function showPetByIndex(param1:int) : void
      {
         var _loc4_:PetRideTranningPetBriefCard = null;
         this.curSelect = param1;
         var _loc2_:int = 0;
         while(_loc2_ < this.petCardContainerAry.length)
         {
            _loc4_ = PetRideTranningPetBriefCard(this.petCardContainerAry[_loc2_]);
            _loc4_.setOnClick(false);
            _loc2_++;
         }
         var _loc3_:PetRideTranningPetBriefCard = PetRideTranningPetBriefCard(this.petCardContainerAry[param1]);
         _loc3_.setOnClick(true);
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this.dispose();
      }
      
      public function dispose() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         PetRide.isShow = false;
      }
      
      private function onClickOk(param1:MouseEvent) : void
      {
         var _loc2_:PetRideInfo = null;
         if(this.curSelect != -1)
         {
            this.selectPetinfo = this.myPets[this.curSelect] as PetBriefInfo;
            _loc2_ = PetRideInfosMap.instance.getPetRideInfo(this.selectPetinfo.viewId);
            if(_loc2_ == null)
            {
               NewDialog.showFailMessage("这只亚比还不适合成为坐骑哦！想了解哪些亚比可以成为坐骑，可以询问骑士训练官哦！");
               return;
            }
            if(!this.rideService.validatePetRideLevelEnough(this.selectPetinfo))
            {
               NewDialog.showFailMessage(this.selectPetinfo.name + "要达到" + _loc2_.getLevel + "级才能成为坐骑哦！");
               return;
            }
            if(this.rideService.validatePetIsTranning(this.selectPetinfo))
            {
               NewDialog.showFailMessage("你选择的亚比已经训练过了！");
               return;
            }
            this.rideService.trainPet(this.selectPetinfo);
            this.dispose();
         }
         else
         {
            NewDialog.showFailMessage("你还没选择要训练的亚比！");
         }
      }
      
      public function show() : void
      {
         ModalDialogManager.getInstance().addModalDialog(this,AlignType.MIDDLE_CENTER,PanelEffect.NONE,false);
      }
   }
}

