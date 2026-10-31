package mmo.pet.pethatchegg
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.floatpanel.FloatPanelManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetEggClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.pet.petcommon.PetHatchMessage;
   import mmo.pet.petcommon.PetReadyHatchEgg;
   
   public class PetHatchEggPanel extends Sprite implements IDispose
   {
      
      private static const perMinute:int = 60;
      
      private static const perHour:int = 60 * 60;
      
      private static const perDay:int = 60 * 60 * 24;
      
      public var putbackBtn:SimpleButton;
      
      private var maxNum:int = 9;
      
      public var numTxt:TextField;
      
      public var xiaoTimeTxt:TextField;
      
      private var allObjectAry:Array = new Array();
      
      private var mesNowpage:int = 1;
      
      private var petDataService:IPetDataService;
      
      public var stopHatchBtn:SimpleButton;
      
      private var state:int = 2;
      
      public var spSprite:Sprite = new Sprite();
      
      public var prevBtn1:SimpleButton;
      
      private var minuteTimer:Timer = new Timer(1000);
      
      private var allpage:int = 1;
      
      public var tuopanel:MovieClip;
      
      private var mesMaxNum:int = 3;
      
      public var stratHatchBtn:SimpleButton;
      
      public var p1:PetHatchMessage;
      
      public var p2:PetHatchMessage;
      
      public var p0:PetHatchMessage;
      
      private var endTime:int = 0;
      
      private var petMesObjAry:Array = new Array();
      
      public var dragMC:MovieClip;
      
      private var itemAry:Array = new Array();
      
      public var eggViewPanel:MovieClip;
      
      private var mesAllpage:int = 1;
      
      private var waitTimer:Timer = new Timer(100,1);
      
      public var timeTxt:TextField;
      
      private var nowpage:int = 1;
      
      public var nextBtn1:SimpleButton;
      
      public var pageTxt1:TextField;
      
      private var btnAry:Array = new Array();
      
      private var petMesItemAry:Array = new Array();
      
      public var btnClose:SimpleButton;
      
      private var eggPanel:MovieClip;
      
      public function PetHatchEggPanel()
      {
         super();
         this.eggPanel = this.eggViewPanel as MovieClip;
         this.eggPanel.hatching.visible = false;
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClickClose);
         SimpleButton(this.eggViewPanel.prevBtn).addEventListener(MouseEvent.CLICK,this.prevPageWin);
         SimpleButton(this.eggViewPanel.nextBtn).addEventListener(MouseEvent.CLICK,this.nextPageWin);
         SimpleButton(this.prevBtn1).addEventListener(MouseEvent.CLICK,this.prevPageMesWin);
         SimpleButton(this.nextBtn1).addEventListener(MouseEvent.CLICK,this.nextPageMesWin);
         SimpleButton(this.stratHatchBtn).addEventListener(MouseEvent.CLICK,this.onStratHatchBtn);
         SimpleButton(this.stopHatchBtn).addEventListener(MouseEvent.CLICK,this.onStopHatchBtn);
         SimpleButton(this.putbackBtn).addEventListener(MouseEvent.CLICK,this.onPutbackBtn);
         this.btnAry.push(SimpleButton(this.stratHatchBtn));
         this.btnAry.push(SimpleButton(this.stopHatchBtn));
         this.btnAry.push(SimpleButton(this.putbackBtn));
         TextField(this.eggViewPanel.pageTxt).text = this.nowpage.toString() + "/" + this.allpage.toString();
         this.petDataService = ServiceContainer.getService("PetDataService") as IPetDataService;
         this.petDataService.addEventListener(PetDataServiceEvent.ONGETHATCHEGGSS,this.onGetHatchEggss);
         PetEggClient.instance.getHatchEggs(this.state);
         this.waitTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onWaitTimerComplete);
         TextField(this.xiaoTimeTxt).text = "";
         TextField(this.timeTxt).text = "";
         TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
         this.petMesItemAry.push(this.p0);
         this.petMesItemAry.push(this.p1);
         this.petMesItemAry.push(this.p2);
         this.dragMC = this.tuopanel as MovieClip;
         TextField(this.numTxt).text = "0";
         this.eggPanel.addChildAt(this.spSprite,this.eggPanel.getChildIndex(this.eggPanel.hatching));
      }
      
      private function prevPageMesWin(param1:MouseEvent) : void
      {
         if(this.mesNowpage > 1)
         {
            --this.mesNowpage;
            TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
            this.addPet(this.petMesObjAry.slice((this.mesNowpage - 1) * this.mesMaxNum,this.mesNowpage * this.mesMaxNum));
         }
      }
      
      public function onTimerComplete(param1:TimerEvent) : void
      {
         this.minuteTimer.stop();
         this.minuteTimer.removeEventListener(TimerEvent.TIMER,this.onTick);
         this.minuteTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
         TextField(this.xiaoTimeTxt).text = "";
         TextField(this.timeTxt).text = "";
         this.waitTimer.reset();
         this.waitTimer.start();
      }
      
      public function beginTime(param1:int) : void
      {
         this.minuteTimer = new Timer(1000,param1);
         this.minuteTimer.addEventListener(TimerEvent.TIMER,this.onTick);
         this.minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
         this.endTime = param1;
         this.minuteTimer.start();
      }
      
      public function onWaitTimerComplete(param1:TimerEvent) : void
      {
         PetEggClient.instance.getHatchEggs(this.state);
      }
      
      private function onStopHatchBtn(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         NewDialog.getSucceedIcon(function(param1:Sprite):*
         {
            var icon:Sprite = param1;
            NewDialog.getCofirmDialog("你要停止孵化吗？",function(param1:ModalDialog):void
            {
               param1.addEventListener(ModalDialogEvent.OK,onOk2);
               param1.addEventListener(ModalDialogEvent.CLOSE,onClose);
               param1.show();
            },this,icon);
         },this);
      }
      
      public function dispose() : void
      {
         this.minuteTimer.stop();
         this.waitTimer.stop();
         this.minuteTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimerComplete);
         this.waitTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onWaitTimerComplete);
         this.petDataService.removeEventListener(PetDataServiceEvent.ONGETHATCHEGGSS,this.onGetHatchEggss);
         PetHatchEgg.isShow = false;
         FloatPanelManager.getInstance().removeFloatPanel(this);
      }
      
      private function prevPageWin(param1:MouseEvent) : void
      {
         if(this.nowpage > 1)
         {
            --this.nowpage;
            TextField(this.eggViewPanel.pageTxt).text = this.nowpage.toString() + "/" + this.allpage.toString();
            this.updateContainer(this.allObjectAry.slice((this.nowpage - 1) * this.maxNum,this.nowpage * this.maxNum));
         }
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         this.dispose();
      }
      
      public function onTick(param1:TimerEvent) : void
      {
         var _loc2_:int = 0;
         if(this.endTime > 0)
         {
            --this.endTime;
            trace("type**********************************************************:" + this.endTime);
            _loc2_ = int(this.endTime / 3600);
            TextField(this.xiaoTimeTxt).text = _loc2_.toString();
            TextField(this.timeTxt).text = int((this.endTime - _loc2_ * 3600) / 60).toString();
         }
      }
      
      private function onClickReadyHatchEgg(param1:MouseEvent) : void
      {
         var _loc2_:PetReadyHatchEgg = param1.currentTarget as PetReadyHatchEgg;
         var _loc3_:Object = _loc2_.obj;
         if(_loc3_.isClick)
         {
            _loc2_.setCheckBox(false);
         }
         else
         {
            _loc2_.setCheckBox(true);
         }
      }
      
      private function updateContainer(param1:Array) : void
      {
         var _loc7_:Object = null;
         var _loc8_:PetReadyHatchEgg = null;
         this.clearContainer();
         var _loc2_:Number = 15;
         var _loc3_:Number = 65;
         var _loc4_:Number = 75;
         var _loc5_:Number = 110;
         var _loc6_:int = 0;
         while(_loc6_ < param1.length)
         {
            if(param1[_loc6_] != undefined)
            {
               _loc7_ = param1[_loc6_] as Object;
               _loc8_ = new PetReadyHatchEgg(param1[_loc6_]);
               _loc8_.x = _loc2_ + int(_loc6_ % 3) * _loc4_;
               _loc8_.y = _loc3_ + int(_loc6_ / 3) * _loc5_;
               _loc8_.addEventListener(MouseEvent.CLICK,this.onClickReadyHatchEgg);
               this.spSprite.addChild(_loc8_);
               this.itemAry.push(_loc8_);
               if(_loc7_.isClick)
               {
                  _loc8_.setCheckBox(true);
               }
               else
               {
                  _loc8_.setCheckBox(false);
               }
            }
            _loc6_++;
         }
      }
      
      private function onStratHatchBtn(param1:MouseEvent) : void
      {
         var pbc:Object = null;
         var evt:MouseEvent = param1;
         var ary:Array = [];
         var i:int = 0;
         while(i < this.allObjectAry.length)
         {
            pbc = this.allObjectAry[i] as Object;
            if(pbc.isClick)
            {
               ary.push(pbc.ei);
            }
            i++;
         }
         if(ary.length != 0 && ary.length < 30)
         {
            NewDialog.getSucceedIcon(function(param1:Sprite):*
            {
               var icon:Sprite = param1;
               NewDialog.getCofirmDialog("你要开始孵蛋吗？",function(param1:ModalDialog):void
               {
                  param1.addEventListener(ModalDialogEvent.OK,onOk1);
                  param1.addEventListener(ModalDialogEvent.CLOSE,onClose);
                  param1.show();
               },this,icon);
            },this);
         }
         else if(ary.length == 0)
         {
            NewDialog.showFailMessage("你还没有放入亚比蛋不能孵化！");
         }
         else
         {
            NewDialog.showFailMessage("亚比蛋的背包已经满了或者孵化蛋的数量已经到了上限！");
         }
      }
      
      private function clearContainer() : void
      {
         var _loc2_:PetReadyHatchEgg = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.itemAry.length)
         {
            _loc2_ = this.itemAry[_loc1_] as PetReadyHatchEgg;
            _loc2_.dispose();
            _loc1_++;
         }
         this.itemAry = [];
      }
      
      public function addPet(param1:Array) : void
      {
         var _loc3_:PetHatchMessage = null;
         this.clearPetMesAry();
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            if(this.petMesItemAry[_loc2_] != undefined)
            {
               _loc3_ = PetHatchMessage(this.petMesItemAry[_loc2_]);
               _loc3_.addObject(param1[_loc2_]);
            }
            _loc2_++;
         }
      }
      
      public function clearPetMesAry() : void
      {
         var _loc2_:PetHatchMessage = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.petMesItemAry.length)
         {
            _loc2_ = this.petMesItemAry[_loc1_] as PetHatchMessage;
            _loc2_.clear();
            _loc1_++;
         }
      }
      
      private function nextPageMesWin(param1:MouseEvent) : void
      {
         if(this.mesNowpage < this.mesAllpage)
         {
            ++this.mesNowpage;
            TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
            this.addPet(this.petMesObjAry.slice((this.mesNowpage - 1) * this.mesMaxNum,this.mesNowpage * this.mesMaxNum));
         }
      }
      
      private function onPutbackBtn(param1:MouseEvent) : void
      {
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         if(this.petMesObjAry.length != 0)
         {
            _loc2_ = 0;
            while(_loc2_ < this.petMesObjAry.length)
            {
               _loc3_ = this.petMesObjAry[_loc2_] as Object;
               PetClient.instance.recyclePm(_loc3_.id,4);
               _loc2_++;
            }
         }
         this.clearPetMesAry();
         this.petMesObjAry = [];
         this.waitTimer.reset();
         this.waitTimer.start();
      }
      
      private function setbtn(param1:int) : void
      {
         var _loc3_:SimpleButton = null;
         var _loc2_:int = 0;
         while(_loc2_ < this.btnAry.length)
         {
            _loc3_ = this.btnAry[_loc2_] as SimpleButton;
            _loc3_.visible = false;
            _loc2_++;
         }
         SimpleButton(this.btnAry[param1]).visible = true;
      }
      
      private function setIsClick(param1:Array) : void
      {
         var _loc3_:Object = null;
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            _loc3_ = param1[_loc2_] as Object;
            _loc3_.isClick = false;
            _loc2_++;
         }
      }
      
      private function onOk(param1:ModalDialogEvent) : void
      {
         PetEggClient.instance.getHatchEggs(this.state);
      }
      
      private function onClose(param1:ModalDialogEvent) : void
      {
         PetEggClient.instance.getHatchEggs(this.state);
      }
      
      private function nextPageWin(param1:MouseEvent) : void
      {
         if(this.nowpage < this.allpage)
         {
            ++this.nowpage;
            TextField(this.eggViewPanel.pageTxt).text = this.nowpage.toString() + "/" + this.allpage.toString();
            this.updateContainer(this.allObjectAry.slice((this.nowpage - 1) * this.maxNum,this.nowpage * this.maxNum));
         }
      }
      
      private function onGetHatchEggss(param1:PetDataServiceEvent) : void
      {
         var _loc2_:int = int(param1.params.st);
         trace("type**********************************************************:" + _loc2_);
         if(_loc2_ == 1)
         {
            PetEggClient.instance.getHatchEggs(this.state);
         }
         else if(_loc2_ == 2)
         {
            this.petMesObjAry = param1.params.es as Array;
            TextField(this.numTxt).text = this.petMesObjAry.length.toString();
            this.mesAllpage = this.petMesObjAry.length / this.mesMaxNum;
            if(this.petMesObjAry.length % this.mesMaxNum != 0)
            {
               ++this.mesAllpage;
            }
            this.beginTime(this.petMesObjAry[0].lt);
            this.addPet(this.petMesObjAry.slice(0,3));
            this.setbtn(1);
            this.eggPanel.hatching.visible = true;
            TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
         }
         else if(_loc2_ == 3)
         {
            NewDialog.showSucceedMessage("有新的亚比孵化出来了");
            this.petMesObjAry = param1.params.pms as Array;
            TextField(this.numTxt).text = this.petMesObjAry.length.toString();
            this.mesAllpage = this.petMesObjAry.length / this.mesMaxNum;
            if(this.petMesObjAry.length % this.mesMaxNum != 0)
            {
               ++this.mesAllpage;
            }
            trace("petMesObjAry:" + this.petMesObjAry.length);
            this.addPet(this.petMesObjAry.slice(0,3));
            this.setbtn(2);
            this.eggPanel.hatching.visible = true;
            TextField(this.xiaoTimeTxt).text = "";
            TextField(this.timeTxt).text = "";
            TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
         }
         else if(_loc2_ == 4)
         {
            this.clearPetMesAry();
            this.allObjectAry = param1.params.es as Array;
            this.setIsClick(this.allObjectAry);
            this.nowpage = 1;
            this.allpage = this.allObjectAry.length / this.maxNum;
            if(this.allObjectAry.length % this.maxNum != 0)
            {
               ++this.allpage;
            }
            if(this.allpage == 0)
            {
               ++this.allpage;
            }
            this.mesNowpage = 1;
            this.mesAllpage = 1;
            TextField(this.pageTxt1).text = this.mesNowpage.toString() + "/" + this.mesAllpage.toString();
            TextField(this.eggViewPanel.pageTxt).text = this.nowpage.toString() + "/" + this.allpage.toString();
            this.updateContainer(this.allObjectAry.slice((this.nowpage - 1) * this.maxNum,this.nowpage * this.maxNum));
            this.eggPanel.hatching.visible = false;
            this.setbtn(0);
            TextField(this.xiaoTimeTxt).text = "";
            TextField(this.timeTxt).text = "";
            TextField(this.numTxt).text = "0";
         }
      }
      
      private function onOk1(param1:ModalDialogEvent) : void
      {
         var _loc4_:Object = null;
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < this.allObjectAry.length)
         {
            _loc4_ = this.allObjectAry[_loc3_] as Object;
            if(_loc4_.isClick)
            {
               _loc2_.push(_loc4_.ei);
            }
            _loc3_++;
         }
         PetEggClient.instance.hatchEggs(this.state,_loc2_);
         this.waitTimer.reset();
         this.waitTimer.start();
      }
      
      private function onOk2(param1:ModalDialogEvent) : void
      {
         PetEggClient.instance.stopHatch(this.state);
         this.minuteTimer.stop();
         this.waitTimer.reset();
         this.waitTimer.start();
      }
      
      public function show() : void
      {
         FloatPanelManager.getInstance().addFloatPanel(this,-1,-1,this.dragMC,1);
      }
   }
}

