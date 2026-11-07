package mmo.activity130131.qiling
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.IMaterialGetPanel;
   import mmo.interfaces.material.MaterialTypes;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMall;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.scheduler.ResScheduler;
   
   public class QilingDlg extends Sprite implements IDispose, IShowPanel
   {
      
      public var btncure:SimpleButton;
      
      public var btnchallenge0:SimpleButton;
      
      public var btnchallenge1:SimpleButton;
      
      public var btnchallenge2:SimpleButton;
      
      public var mcqlw2:MovieClip;
      
      public var mcqlw0:MovieClip;
      
      private var FncTable:Object;
      
      public var mcqlw1:MovieClip;
      
      public var btnclose:SimpleButton;
      
      public var btnrecipe:SimpleButton;
      
      public var mccenter:MovieClip;
      
      private var modal:QilingModal;
      
      private const Stone_Id:Array = [494,495,496];
      
      public var spwinlabel:MovieClip;
      
      public function QilingDlg()
      {
         this.FncTable = {
            "btnclose":this.handleClose,
            "btnrecipe":this.handleRecipe,
            "btncure":this.handleCure,
            "btnbeckon":this.handleBeckon,
            "btnpresent":this.handlePresent,
            "btnbossfight":this.handleBossFight
         };
         super();
         this.modal = new QilingModal();
      }
      
      private function handleRecipe() : void
      {
         var panel:MovieClip = null;
         if(this.modal.getChallengState() < QilingModal.CHALLENGE_STATE_HAVENT_WIN)
         {
            panel = new RecipeDlg1();
         }
         else
         {
            panel = new RecipeDlg2();
         }
         panel.btnclose.addEventListener(MouseEvent.CLICK,function(param1:MouseEvent):void
         {
            panel.btnclose.removeEventListener(MouseEvent.CLICK,arguments.callee);
            ModalDialogManager.getInstance().removeModalDialog(panel);
         });
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(panel);
      }
      
      private function handleStarPower(param1:int) : void
      {
         var powerPanel:MovieClip = null;
         var closeFnc:Function = null;
         var buyFnc:Function = null;
         var index:int = param1;
         powerPanel = new PowerPanel();
         closeFnc = function(param1:MouseEvent):void
         {
            powerPanel.btnclose.removeEventListener(MouseEvent.CLICK,closeFnc);
            powerPanel.btnbuy.removeEventListener(MouseEvent.CLICK,buyFnc);
            ModalDialogManager.getInstance().removeModalDialog(powerPanel);
         };
         buyFnc = function(param1:MouseEvent):void
         {
            closeFnc(null);
            handleBuy(index);
         };
         powerPanel.btnclose.addEventListener(MouseEvent.CLICK,closeFnc);
         powerPanel.btnbuy.addEventListener(MouseEvent.CLICK,buyFnc);
         powerPanel.color.gotoAndStop(index + 1);
         powerPanel.money.gotoAndStop(index + 1);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(powerPanel);
         SundriesClient.logOpen("222");
      }
      
      private function handleCure() : void
      {
         QilingUtil.tryCure();
      }
      
      private function isPassAll() : Boolean
      {
         var _loc1_:Array = this.modal.getAllColor();
         var _loc2_:Array = this.modal.getAllColorState();
         var _loc3_:int = int(_loc1_.length);
         var _loc4_:Boolean = true;
         var _loc5_:int = 0;
         while(_loc5_ < _loc3_)
         {
            if(_loc2_[_loc1_[_loc5_]] == QilingModal.COLOR_STATE_NOT_PASS)
            {
               _loc4_ = false;
               break;
            }
            _loc5_++;
         }
         return _loc4_;
      }
      
      public function showPanel() : void
      {
         if(this.checkOpenMovie())
         {
            this.showPanelInternal();
         }
         else
         {
            ProgressFullSprite.show();
            ResScheduler.getResource("activityres/activity130131/qiling/openmovie",function(param1:MovieClip):void
            {
               var mc:MovieClip = param1;
               ProgressFullSprite.show();
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  ProgressFullSprite.close();
                  DisplayUtil.stop(mc);
                  ModalDialogManager.getInstance().removeModalDialog(mc);
                  showPanelInternal();
                  LocalStore.setValue(UserInfo.userName,true,"activity130131_qiling_openmovie");
               });
               ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc,AlignType.NONE);
            },"mmo.activity130131.qiling.OpenMovie");
         }
      }
      
      private function updateState(param1:Function, param2:Object) : void
      {
         var callback:Function = param1;
         var thisObj:Object = param2;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(QilingClient.CmdInfo,function(param1:SocketClientEvent):void
         {
            ProgressFullSprite.close();
            SocketClient.instance.removeEventListener(QilingClient.CmdInfo,arguments.callee);
            modal.parseInfo(param1.params.info);
            if(callback != null)
            {
               callback.apply(thisObj);
            }
         });
         QilingClient.instance.getInfo();
      }
      
      private function handleStartFight(param1:int) : void
      {
         var petFight:IPetFight;
         var enterFightFailFnc:Function = null;
         var fightEndFnc:Function = null;
         var index:int = param1;
         if(!this.checkTeam())
         {
            return;
         }
         enterFightFailFnc = function(param1:PetFightEvent):void
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,enterFightFailFnc);
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,fightEndFnc);
         };
         fightEndFnc = function(param1:PetFightEvent):void
         {
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,enterFightFailFnc);
            CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,fightEndFnc);
            var _loc2_:QilingDlg = new QilingDlg();
            _loc2_.showPanel();
         };
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,enterFightFailFnc);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,fightEndFnc);
         petFight = ServiceContainer.getService(IPetFight) as IPetFight;
         petFight.startFight(99,false,{
            "handler":"qiling0201",
            "index":index
         });
      }
      
      private function handleBeckon() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(QilingClient.CmdExchange,function(param1:SocketClientEvent):void
         {
            var mc:MovieClip = null;
            var evt:SocketClientEvent = param1;
            ProgressFullSprite.close();
            if(evt.params.suc)
            {
               mc = new BeckonMovie();
               mc.addFrameScript(mc.totalFrames - 1,function():void
               {
                  var service:IMaterialGetPanel;
                  DisplayUtil.stop(mc);
                  ModalDialogManager.getInstance().removeModalDialog(mc);
                  service = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
                  service.showPanel(MaterialTypes.PET_EGG,793,1,function():void
                  {
                     modal.setChallengState(QilingModal.CHALLENGE_STATE_HAVENT_WIN);
                     updateUi();
                  });
               });
               ModalDialogManager.getInstance().addModalDialogWithChangLayer(mc,AlignType.NONE);
            }
            else
            {
               NewDialog.showFailMessage("召唤失败！");
            }
         });
         QilingClient.instance.exchange();
      }
      
      private function checkOpenMovie() : Boolean
      {
         var _loc1_:Boolean = Boolean(LocalStore.getValue(UserInfo.userName,"activity130131_qiling_openmovie"));
         // REVIVAL: the later LocalStore.allowStore (the 2013 one has none): storing is allowed.
         var _loc2_:Boolean = false;
         if(_loc1_ || !_loc1_ && _loc2_)
         {
            return true;
         }
         return false;
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function handleBossFight() : void
      {
         if(!this.checkTeam())
         {
            return;
         }
         this.handleStartFight(3);
      }
      
      public function showPanelInternal() : void
      {
         SundriesClient.logEvent(1323);
         addEventListener(MouseEvent.CLICK,this.onClick);
         this.updateState(function():void
         {
            updateUi();
            ModalDialogManager.getInstance().addModalDialogWithChangLayer(this as DisplayObject);
         },this);
      }
      
      private function checkTeam() : Boolean
      {
         var _loc1_:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         if(Boolean(_loc1_.isLeader()) || Boolean(_loc1_.isMember()))
         {
            NewDialog.showFailMessage("组队中不能进行奇灵王挑战哦！");
            return false;
         }
         return true;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc3_:Function = null;
         var _loc2_:String = DisplayObject(param1.target).name;
         if(this.FncTable.hasOwnProperty(_loc2_))
         {
            _loc3_ = this.FncTable[_loc2_] as Function;
            _loc3_.apply(this);
         }
         else if(_loc2_.indexOf("btnchallenge") != -1)
         {
            this.handleChallenge(parseInt(_loc2_.substr(String("btnchallenge").length)));
         }
      }
      
      private function handleChallenge(param1:int) : void
      {
         var startPanel:MovieClip = null;
         var spclosefnc:Function = null;
         var spstartfnc:Function = null;
         var spstarpowfnc:Function = null;
         var index:int = param1;
         startPanel = new StartPanel();
         spclosefnc = function(param1:MouseEvent):void
         {
            startPanel.btnclose.removeEventListener(MouseEvent.CLICK,spclosefnc);
            startPanel.btnstart.removeEventListener(MouseEvent.CLICK,spstartfnc);
            startPanel.btnstarpow.removeEventListener(MouseEvent.CLICK,spstarpowfnc);
            ModalDialogManager.getInstance().removeModalDialog(startPanel);
         };
         spstartfnc = function(param1:MouseEvent):void
         {
            spclosefnc.apply(null,[null]);
            handleStartFight(index);
         };
         spstarpowfnc = function(param1:MouseEvent):void
         {
            spclosefnc.apply(null,[null]);
            handleStarPower(index);
         };
         startPanel.btnclose.addEventListener(MouseEvent.CLICK,spclosefnc);
         startPanel.btnstart.addEventListener(MouseEvent.CLICK,spstartfnc);
         startPanel.btnstarpow.addEventListener(MouseEvent.CLICK,spstarpowfnc);
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(startPanel);
      }
      
      private function handleClose() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function reshowPanel() : void
      {
         addEventListener(MouseEvent.CLICK,this.onClick);
         this.updateUi();
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }
      
      private function handlePresent() : void
      {
         ProgressFullSprite.show();
         ServiceContainer.tryGetService(IRmbShoppingMall,function(param1:IRmbShoppingMall, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showRmbShoppingPanel(6);
         });
      }
      
      private function updateUi() : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:SimpleButton = null;
         var _loc1_:Array = this.modal.getAllColor();
         var _loc2_:Array = this.modal.getAllColorState();
         var _loc3_:int = int(_loc1_.length);
         var _loc6_:int = 0;
         while(_loc6_ < _loc3_)
         {
            _loc4_ = getChildByName("mcqlw" + _loc6_) as MovieClip;
            _loc5_ = getChildByName("btnchallenge" + _loc6_) as SimpleButton;
            TipsManager.getInstance().removeTips(_loc4_);
            if(_loc2_[_loc1_[_loc6_]] == QilingModal.COLOR_STATE_PASS)
            {
               _loc4_.gotoAndStop(2);
               _loc5_.visible = false;
            }
            else if(_loc2_[_loc1_[_loc6_]] == QilingModal.COLOR_STATE_NOT_PASS)
            {
               _loc4_.gotoAndStop(1);
               _loc5_.visible = true;
               TipsManager.getInstance().addTips(_loc4_,"通过此试炼就可以获得" + QilingModal.COLOR_NAMES[_loc6_] + "奇灵玉哦！");
            }
            _loc6_++;
         }
         var _loc7_:MovieClip = getChildByName("mccenter") as MovieClip;
         _loc7_.filters = null;
         _loc7_.mouseChildren = true;
         var _loc8_:Sprite = getChildByName("spwinlabel") as Sprite;
         _loc8_.visible = false;
         TipsManager.getInstance().removeTips(_loc7_);
         switch(this.modal.getChallengState())
         {
            case QilingModal.CHALLENGE_STATE_HAVENT_COLLECT_ALL:
               _loc7_.gotoAndStop(1);
               DisplayUtil.applyGray(_loc7_);
               _loc7_.mouseChildren = false;
               TipsManager.getInstance().addTips(_loc7_,"集齐三色奇灵玉才能召唤奇灵王哦！快去挑战吧！");
               break;
            case QilingModal.CHALLENGE_STATE_HAVENT_EXCHANGE:
               _loc7_.gotoAndStop(2);
               break;
            case QilingModal.CHALLENGE_STATE_HAVENT_WIN:
               _loc8_.visible = true;
               _loc7_.gotoAndStop(3);
               break;
            case QilingModal.CHALLENGE_STATE_WIN:
               _loc8_.visible = true;
               _loc7_.gotoAndStop(4);
               DisplayUtil.applyGray(_loc7_);
               _loc7_.mouseChildren = false;
               TipsManager.getInstance().addTips(_loc7_,"你已经通过终极挑战了哦！");
         }
      }
      
      private function handleBuy(param1:int) : void
      {
         var index:int = param1;
         QilingUtil.buy(this.Stone_Id[index],1,function():void
         {
            var service:IMaterialGetPanel;
            SundriesClient.logBuy("222",0,[[1,MaterialTypes.ITEM,Stone_Id[index]]]);
            service = ServiceContainer.getService(IMaterialGetPanel) as IMaterialGetPanel;
            service.showPanel(MaterialTypes.ITEM,Stone_Id[index],1,function():void
            {
               modal.setColorState(index,QilingModal.COLOR_STATE_PASS);
               if(isPassAll())
               {
                  modal.setChallengState(QilingModal.CHALLENGE_STATE_HAVENT_EXCHANGE);
               }
               updateUi();
            });
         });
      }
   }
}

