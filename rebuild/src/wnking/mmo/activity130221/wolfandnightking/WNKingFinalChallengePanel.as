package mmo.activity130221.wolfandnightking
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.loader.scheduler.ResScheduler;
   
   public class WNKingFinalChallengePanel extends WNKingPanelBase
   {
      
      public var btnpackage:SimpleButton;
      
      public var txtNum:TextField;
      
      public var btnClose:SimpleButton;
      
      public var btnCure:SimpleButton;
      
      public var spFinal:MovieClip;
      
      public var btnFight:SimpleButton;
      
      public var btnstore:SimpleButton;
      
      public var btnReturn:SimpleButton;
      
      public var btnTips:SimpleButton;
      
      private var canFight:Boolean = true;
      
      public function WNKingFinalChallengePanel()
      {
         super();
         this.getState();
      }
      
      private function getState() : void
      {
         this.visible = false;
         SocketClient.instance.addEventListener("nwk0219-3",this.onState);
         SocketClient.instance.sendXtMessage("HolidayExtension","nwk0219-3",{});
      }
      
      private function onState(param1:SocketClientEvent) : void
      {
         this.visible = true;
         SocketClient.instance.removeEventListener("nwk0219-3",this.onState);
         var _loc2_:TextField = this.getChildByName("txtNum") as TextField;
         _loc2_.mouseEnabled = false;
         _loc2_.text = int(5 - param1.params.c).toString();
         // REBUILT: the 已战胜 stamp shows once the 终极试炼 is won (the surviving copy leaves it on).
         this.spFinal.visible = Boolean(param1.params.won);
         if(param1.params.c >= 5)
         {
            this.canFight = false;
            DisplayUtil.applyGray(this.btnFight);
            TipsManager.getInstance().addTips(this.btnFight,"你已经不能再挑战了！");
         }
      }
      
      override protected function clickBtn(param1:MouseEvent) : void
      {
         var _loc2_:String = param1.target.name as String;
         switch(_loc2_)
         {
            case "btnClose":
               this.closePanel();
               break;
            case "btnReturn":
               this.closePanel();
               new WNKingChallengeMainPanel().showPanel();
               break;
            case "btnCure":
               this.tryCure();
               break;
            case "btnTips":
               this.showTipsPanel();
               break;
            case "btnFight":
               this.tryFight();
               break;
            case "btnpackage":
               WNKingPets.openPetPackage();
               break;
            case "btnstore":
               WNKingPets.tryOpenPetStore();
         }
      }
      
      private function tryFight() : void
      {
         if(!this.canFight)
         {
            return;
         }
         new WNKingFightHandler(2,0,this.onFightWin,this.onFightFail).handleFight();
      }
      
      private function onFightWin() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getTempResource("activityres/activity130221/wolfandnightking/wolfandnightkingfinalmovie",function(param1:MovieClip, param2:Object = null):void
         {
            var mc:MovieClip = param1;
            var params:Object = param2;
            ProgressFullSprite.close();
            mc.addFrameScript(mc.totalFrames - 1,function():void
            {
               mc.stop();
               ModalDialogManager.getInstance().removeModalDialog(mc);
               new WNKingChallengeMainPanel().showPanel();
            });
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc,AlignType.NONE);
            mc.gotoAndPlay(1);
         },"mmo.activity130221.wolfandnightking.FinalMovie");
      }
      
      private function onFightFail() : void
      {
         new WNKingFinalChallengePanel().showPanel();
      }
      
      private function tryCure() : void
      {
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         if(_loc1_.checkPetIsEmpty())
         {
            NewDialog.showMessage("你的背包里没有亚比哦！");
            return;
         }
         if(Boolean(_loc1_.checkAllPetHPIsFull()) && Boolean(_loc1_.checkAllPetPPIsFull()))
         {
            NewDialog.showMessage("你背包里的亚比已经充满活力，不需要治疗哦！");
            return;
         }
         _loc1_.recureAllPet();
      }
      
      private function showTipsPanel() : void
      {
         new WNKingFinalTipsPanel().showPanel();
      }
   }
}

