package mmo.pet.petcommon
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.geom.Rectangle;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   
   /**
    * ERA pet/pethatchegg (December 2010), rebuilt from its decompiled code: one
    * row of the 孵化器's list. While an egg hatches its row now shows the egg's
    * picture in the row's empty frame (the era row showed only 孵化中...).
    */
   public class PetHatchMessage extends Sprite
   {
      
      public var mTxt:TextField;
      
      public var characterTxt:TextField;
      
      private var petDataService:IPetDataService;
      
      public var nameIdTxt:TextField;
      
      public var xxbtn:SimpleButton;
      
      public var nameTxt:TextField;
      
      public var simpleObj:PetDetailedInfo;
      
      public var littleGif:MovieClip;
      
      public var obj:Object = new Object();

      private var eggIcon:Sprite;
      
      public function PetHatchMessage()
      {
         super();
         this.petDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         SimpleButton(this.xxbtn).addEventListener(MouseEvent.CLICK,this.onClick);
         MovieClip(this.littleGif).visible = false;
      }
      
      public function addObject(param1:Object) : void
      {
         this.obj = param1;
         if(param1.ei == undefined)
         {
            this.setPetMes(param1);
         }
         else
         {
            this.setMes(param1);
         }
      }
      
      private function setGif(param1:MovieClip, param2:int) : void
      {
         var _loc3_:String = "";
         if(param2 >= 0 && param2 <= 9)
         {
            MovieClip(param1).gotoAndStop(1);
            _loc3_ = "一无是处";
         }
         else if(param2 >= 10 && param2 <= 14)
         {
            MovieClip(param1).gotoAndStop(2);
            _loc3_ = "十分常见";
         }
         else if(param2 >= 15 && param2 <= 19)
         {
            MovieClip(param1).gotoAndStop(3);
            _loc3_ = "百里挑一";
         }
         else if(param2 >= 20 && param2 <= 24)
         {
            MovieClip(param1).gotoAndStop(4);
            _loc3_ = "千载难逢";
         }
         else if(param2 >= 25 && param2 <= 29)
         {
            MovieClip(param1).gotoAndStop(5);
            _loc3_ = "万众瞩目";
         }
         else if(param2 == 30)
         {
            MovieClip(param1).gotoAndStop(6);
            _loc3_ = "王者无敌";
         }
         TipsManager.getInstance().removeTips(InteractiveObject(param1));
         TipsManager.getInstance().addTips(InteractiveObject(param1) as InteractiveObject,_loc3_,0);
      }
      
      private function removeEgg() : void
      {
         if(this.eggIcon != null && this.eggIcon.parent != null)
         {
            this.eggIcon.parent.removeChild(this.eggIcon);
         }
         this.eggIcon = null;
      }

      /** The egg's picture centred in the row's frame (its left square, as tall as the row). */
      private function showEgg(ri:int) : void
      {
         this.removeEgg();
         var svc:IPetSkillMesService = ServiceContainer.getService("PetSkillMesService") as IPetSkillMesService;
         if(svc == null || ri <= 0)
         {
            return;
         }
         var b:Rectangle = this.getBounds(this);
         var side:Number = Math.min(b.height, 90);
         this.eggIcon = svc.getPetEggIconByRaceId(ri);
         this.eggIcon.mouseEnabled = this.eggIcon.mouseChildren = false;
         DisplayUtil.scaleDisplay(this.eggIcon,side * 0.7,side * 0.7);
         this.eggIcon.x = b.left + (side - this.eggIcon.width) / 2;
         this.eggIcon.y = b.top + (side - this.eggIcon.height) / 2;
         this.addChild(this.eggIcon);
      }

      public function clear() : void
      {
         this.removeEgg();
         this.obj = null;
         this.simpleObj = null;
         MovieClip(this.littleGif).visible = false;
         TextField(this.nameIdTxt).text = "?";
         TextField(this.nameTxt).text = "?";
         TextField(this.characterTxt).text = "?";
         TextField(this.mTxt).text = "";
         this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewPet);
      }
      
      public function setMes(param1:Object) : void
      {
         TextField(this.nameIdTxt).text = "?";
         TextField(this.nameTxt).text = "?";
         TextField(this.characterTxt).text = "?";
         TextField(this.mTxt).text = "孵化中...";
         MovieClip(this.littleGif).visible = false;
         this.showEgg(int(param1.ri));
      }
      
      private function onViewPet(param1:PetDataServiceEvent) : void
      {
         var _loc2_:PetDetailedInfo = new PetDetailedInfo();
         _loc2_.parseInfo(param1.params.pm);
         if(this.simpleObj == null && this.obj.id == _loc2_.id)
         {
            this.petDataService.removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewPet);
            this.simpleObj = _loc2_;
            trace("-----------------------------------------------------------------------------------------------ccccccccccccc222222:");
            this.showPet(_loc2_);
         }
      }
      
      private function showPet(param1:PetDetailedInfo) : void
      {
         trace("-----------------------------------------------------------------------------------------------ccccccccccccc333333:");
         TextField(this.nameIdTxt).text = param1.id.toString();
         TextField(this.nameTxt).text = param1.name.toString();
         TextField(this.characterTxt).text = param1.character.toString();
         var _loc2_:int = 0;
         var _loc3_:Array = [param1.indAtt,param1.indDef,param1.indSAtt,param1.indSDef,param1.indHP,param1.indSpd];
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            _loc2_ += this.setTotalNum(int(_loc3_[_loc4_]));
            _loc4_++;
         }
         MovieClip(this.littleGif).visible = true;
         this.setGif(this.littleGif,_loc2_);
      }
      
      private function setTotalNum(param1:int) : int
      {
         if(param1 >= 0 && param1 <= 10)
         {
            return 1;
         }
         if(param1 >= 11 && param1 <= 20)
         {
            return 2;
         }
         if(param1 >= 21 && param1 <= 30)
         {
            return 3;
         }
         if(param1 >= 31 && param1 <= 50)
         {
            return 4;
         }
         if(param1 >= 51 && param1 <= 62)
         {
            return 5;
         }
         return 0;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         if(this.simpleObj != null)
         {
            this.petDataService.dispatchEvent(new PetCommonEvent(PetCommonEvent.PETHATCHMESSAGE,this.simpleObj));
         }
      }
      
      public function setPetMes(param1:Object) : void
      {
         TextField(this.mTxt).text = "";
         trace("-----------------------------------------------------------------------------------------------ccccccccccccc111111:");
         this.petDataService.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM,this.onViewPet);
         PetClient.instance.viewSinglePM(param1.id);
      }
   }
}

