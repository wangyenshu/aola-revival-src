package mmo.pet.petride
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetRideInfosMap;
   import mmo.interfaces.pet.peticon.IPetIcon;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.ride.IRideService;
   
   public class PetRideTranningPetBriefCard extends Sprite
   {
      
      public var hpmc:MovieClip;
      
      public var iconcontainer:MovieClip;
      
      public var ps:MovieClip;
      
      public var rideflag:MovieClip;
      
      public var txtHp:TextField;
      
      public var txtLevel:TextField;
      
      public var txtName:TextField;
      
      public var petInfo:PetBriefInfo;
      
      private var mc:MovieClip;
      
      private var petID:int = -1;
      
      private var petIconContainer:MovieClip;
      
      private var icon:PetIconContainer;
      
      private var rideFlag:MovieClip;
      
      public function PetRideTranningPetBriefCard(param1:PetBriefInfo)
      {
         super();
         this.petInfo = param1;
         TextField(this.txtName).text = param1.name;
         this.petID = param1.id;
         this.petIconContainer = this.getChildByName("iconcontainer") as MovieClip;
         this.update();
         this.rideFlag = this.rideflag;
         this.rideFlag.visible = false;
         var _loc2_:IRideService = ServiceContainer.getService(IRideService) as IRideService;
         if(Boolean(_loc2_.validatePetIsTranning(param1)) && PetRideInfosMap.instance.getPetRideInfo(param1.viewId) != null)
         {
            this.rideFlag.visible = true;
         }
         this.mc = MovieClip(this.ps);
         this.mc.gotoAndStop(1);
         this.buttonMode = true;
         this.useHandCursor = true;
      }
      
      public function update() : void
      {
         TextField(this.txtHp).text = this.petInfo.curHp.toString() + "/" + this.petInfo.maxHp.toString();
         TextField(this.txtLevel).text = this.petInfo.level.toString();
         var _loc1_:int = 100 * (this.petInfo.curHp / this.petInfo.maxHp);
         if(_loc1_ == 0)
         {
            MovieClip(this.hpmc).gotoAndStop(1);
         }
         else
         {
            MovieClip(this.hpmc).gotoAndStop(_loc1_);
         }
         var _loc2_:IPetIcon = ServiceContainer.getService("PetIconService") as IPetIcon;
         this.icon = _loc2_.getPetIcon(this.petInfo.viewId,PetIconType.SMALL,false);
         this.icon.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onIconLoaded);
         this.icon.startLoad();
      }
      
      private function onIconLoaded(param1:PetIconEvent) : void
      {
         if(param1.raceId == this.petInfo.viewId)
         {
            this.icon.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onIconLoaded);
            this.addPetIconToContainer(this.petIconContainer,this.icon);
         }
      }
      
      private function addPetIconToContainer(param1:DisplayObjectContainer, param2:DisplayObject) : void
      {
         var _loc3_:PetIconContainer = null;
         var _loc4_:int = 0;
         while(_loc4_ < param1.numChildren)
         {
            if(param1.getChildAt(_loc4_) is PetIconContainer)
            {
               _loc3_ = param1.getChildAt(_loc4_) as PetIconContainer;
            }
            _loc4_++;
         }
         if(_loc3_ != null)
         {
            DisplayUtil.stopAndRemove(_loc3_);
         }
         DisplayUtil.middleDisplay(param2,param1.width,param1.height);
         param1.addChild(param2);
      }
      
      public function getPetId() : int
      {
         return this.petID;
      }
      
      public function setOnClick(param1:Boolean) : void
      {
         if(param1)
         {
            MovieClip(this.mc).gotoAndStop(2);
         }
         else
         {
            MovieClip(this.mc).gotoAndStop(1);
         }
      }
      
      public function dispose() : void
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.petIconContainer.numChildren)
         {
            this.petIconContainer.removeChildAt(0);
            _loc1_++;
         }
         this.petIconContainer = null;
      }
   }
}

