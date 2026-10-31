package mmo.pet.petcommon
{
   import flash.display.InteractiveObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDetailedInfo;
   
   public class PetHatchEggFinishMes extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var dr:MovieClip;
      
      private var petDataService:IPetDataService;
      
      public var s0:TextField;
      
      public var s1:TextField;
      
      public var s2:TextField;
      
      public var s3:TextField;
      
      public var s4:TextField;
      
      public var s5:TextField;
      
      public var k0:PetLevelStar;
      
      public var k1:PetLevelStar;
      
      public var k2:PetLevelStar;
      
      public var k3:PetLevelStar;
      
      public var k4:PetLevelStar;
      
      public var k5:PetLevelStar;
      
      public var btnwhy:SimpleButton;
      
      public var littleGif:MovieClip;
      
      private var starAry:Array = new Array();
      
      public function PetHatchEggFinishMes()
      {
         super();
         this.petDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         var _loc1_:int = 0;
         while(_loc1_ < 6)
         {
            this.starAry.push(this.getChildByName("k" + _loc1_) as PetLevelStar);
            _loc1_++;
         }
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         this.petDataService.addEventListener(PetCommonEvent.PETHATCHMESSAGE,this.onPethatchmessage);
         SimpleButton(this.btnwhy).addEventListener(MouseEvent.CLICK,this.onClickWhy);
         MovieClip(this.dr).visible = false;
         this.visible = false;
      }
      
      private function onPethatchmessage(param1:PetCommonEvent) : void
      {
         this.update(PetDetailedInfo(param1.params));
      }
      
      public function update(param1:PetDetailedInfo) : void
      {
         var _loc7_:PetLevelStar = null;
         var _loc8_:PetLevelStar = null;
         MovieClip(this.dr).visible = false;
         var _loc2_:int = 0;
         while(_loc2_ < this.starAry.length)
         {
            _loc7_ = this.starAry[_loc2_] as PetLevelStar;
            _loc7_.clear();
            _loc2_++;
         }
         var _loc3_:Array = [param1.indAtt,param1.indSAtt,param1.indDef,param1.indSDef,param1.indHP,param1.indSpd];
         var _loc4_:int = 0;
         while(_loc4_ < this.starAry.length)
         {
            _loc8_ = this.starAry[_loc4_] as PetLevelStar;
            this.setGif(_loc8_,int(_loc3_[_loc4_]));
            _loc4_++;
         }
         TextField(this.s0).text = param1.indAtt.toString();
         TextField(this.s1).text = param1.indSAtt.toString();
         TextField(this.s2).text = param1.indDef.toString();
         TextField(this.s3).text = param1.indSDef.toString();
         TextField(this.s4).text = param1.indHP.toString();
         TextField(this.s5).text = param1.indSpd.toString();
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc6_ < _loc3_.length)
         {
            _loc5_ += this.setTotalNum(int(_loc3_[_loc6_]));
            _loc6_++;
         }
         this.setGif1(this.littleGif,_loc5_);
         this.visible = true;
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this.visible = false;
      }
      
      private function setGif(param1:PetLevelStar, param2:int) : void
      {
         trace("PetLevelStar.name = " + param1.name);
         trace("num = " + param2);
         if(param2 >= 0 && param2 <= 10)
         {
            param1.setLevel(1);
         }
         else if(param2 >= 11 && param2 <= 20)
         {
            param1.setLevel(2);
         }
         else if(param2 >= 21 && param2 <= 30)
         {
            param1.setLevel(3);
         }
         else if(param2 >= 31 && param2 <= 50)
         {
            param1.setLevel(4);
         }
         else if(param2 >= 51 && param2 <= 62)
         {
            param1.setLevel(5);
         }
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
      
      private function setGif1(param1:MovieClip, param2:int) : void
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
      
      private function onClickWhy(param1:MouseEvent) : void
      {
         if(MovieClip(this.dr).visible)
         {
            MovieClip(this.dr).visible = false;
         }
         else
         {
            MovieClip(this.dr).visible = true;
         }
      }
   }
}

