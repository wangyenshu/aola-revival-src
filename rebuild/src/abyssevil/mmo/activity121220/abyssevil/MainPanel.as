package mmo.activity121220.abyssevil
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.AlignType;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.shareobject.LocalStore;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.PanelEvent;
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
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.team.ITeamService;
   import mmo.loader.scheduler.ResScheduler;
   
   public class MainPanel extends Sprite implements IDispose, IShowPanel
   {
      
      public var light0:MovieClip;
      
      public var light1:MovieClip;
      
      public var light2:MovieClip;
      
      public var btncure:SimpleButton;
      
      public var btnclose:SimpleButton;
      
      public var win0:MovieClip;
      
      public var btnchallenge:SimpleButton;
      
      public var win1:MovieClip;
      
      public var win2:MovieClip;
      
      public var boss0:MovieClip;
      
      public var btnmoney:SimpleButton;
      
      public var boss1:MovieClip;
      
      public var btnevo:SimpleButton;
      
      public var boss2:MovieClip;
      
      public var lefttimestxt:TextField;
      
      private const firstShowKey:String = "abyssevil_121221_first_show_key";
      
      private var winTipMcs:Array = [];
      
      private var lightMcs:Array = [];
      
      private var bossMcs:Array = [];
      
      private var leftTimeTxt:TextField;
      
      private var starPowerBtn:SimpleButton;
      
      private var challengeBtn:SimpleButton;
      
      private var evoBtn:SimpleButton;
      
      private var leftTimes:int;
      
      private var state:int;
      
      private var teamService:ITeamService;
      
      public function MainPanel()
      {
         var _loc2_:MovieClip = null;
         super();
         var _loc1_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = getChildByName("win" + _loc1_) as MovieClip;
            this.winTipMcs.push(_loc2_);
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = getChildByName("light" + _loc1_) as MovieClip;
            this.lightMcs.push(_loc2_);
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < 3)
         {
            _loc2_ = getChildByName("boss" + _loc1_) as MovieClip;
            this.bossMcs.push(_loc2_);
            _loc1_++;
         }
         this.leftTimeTxt = getChildByName("lefttimestxt") as TextField;
         this.leftTimeTxt.selectable = false;
         this.starPowerBtn = getChildByName("btnmoney") as SimpleButton;
         this.challengeBtn = getChildByName("btnchallenge") as SimpleButton;
         this.evoBtn = getChildByName("btnevo") as SimpleButton;
         this.teamService = ServiceContainer.instance.getService(ITeamService) as ITeamService;
         this.addBuff();
      }
      
      private function addBuff() : void
      {
         // The later panel showed the player's buffs here (IBuffCache, not in the 2013 interfaces).
      }
      
      public function dispose() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
         this.teamService.refuseInvite(false);
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc2_:String = DisplayObject(param1.target).name;
         switch(_loc2_)
         {
            case "btnclose":
               this.close();
               break;
            case "btnstory":
               this.story();
               break;
            case "btnsecret":
               this.secret();
               break;
            case "btncure":
               this.cure();
               break;
            case "btnmoney":
               this.money();
               break;
            case "btnchallenge":
               this.challenge();
               break;
            case "btnevo":
               this.evo();
         }
      }
      
      private function evo() : void
      {
         if(!this.evoBtn.enabled)
         {
            return;
         }
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(AbyssevilClient.CMD_WAKE_UP_DRAGON,this.onWakeUp);
         AbyssevilClient.instance().wakeupDragon();
      }
      
      private function onWakeUp(param1:SocketClientEvent) : void
      {
         var e:SocketClientEvent = param1;
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(AbyssevilClient.CMD_WAKE_UP_DRAGON,this.onWakeUp);
         if(Boolean(e.params.succ))
         {
            ++this.state;
            this.updatePanel();
            ProgressFullSprite.show();
            ResScheduler.getResource("activityres/activity121220/abyssevilwinmovie",function(param1:MovieClip):void
            {
               var c:MovieClip = param1;
               ProgressFullSprite.close();
               c.addFrameScript(c.totalFrames - 1,function():void
               {
                  ModalDialogManager.getInstance().removeModalDialog(c);
                  c.stop();
                  var _loc1_:IMaterialGetPanel = ServiceContainer.instance.getService(IMaterialGetPanel) as IMaterialGetPanel;
                  _loc1_.showPanel(MaterialTypes.PET_EGG,1348,1);
               });
               ModalDialogManager.getInstance().addModalDialogWithChangLayer(c,AlignType.NONE);
               c.gotoAndPlay(1);
            },"mmo.activity121220.abyssevil.WinMovie");
         }
         else
         {
            NewDialog.showFailMessage("进化失败！");
         }
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }
      
      private function story() : void
      {
         ProgressFullSprite.show();
         ResScheduler.getResource("activityres/activity121220/abyssevilstorybook",function(param1:IShowPanel):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
         },"mmo.activity121220.abyssevil.StoryBook");
      }
      
      private function secret() : void
      {
         var _loc1_:IShowPanel = new SecretPanel();
         _loc1_.showPanel();
      }
      
      private function cure() : void
      {
         PetCureHandler.tryCure();
      }
      
      private function money() : void
      {
         if(!this.starPowerBtn.enabled)
         {
            return;
         }
         var _loc1_:IShowPanel = new MoneyPanel(this.buySuccess);
         _loc1_.showPanel();
      }
      
      private function buySuccess() : void
      {
      }
      
      private function challenge() : void
      {
         var _loc4_:PetBriefInfo = null;
         var _loc6_:int = 0;
         var _loc7_:IShowPanel = null;
         if(!this.challengeBtn.enabled)
         {
            return;
         }
         var _loc1_:ITeamService = ServiceContainer.instance.getService(ITeamService) as ITeamService;
         if(_loc1_.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态中不能进行魔将挑战哦！");
            return;
         }
         var _loc2_:IPetDataService = ServiceContainer.instance.getService(IPetDataService) as IPetDataService;
         var _loc3_:Array = _loc2_.getMyPets();
         var _loc5_:Boolean = false;
         if(_loc3_ != null)
         {
            _loc6_ = 0;
            while(_loc6_ < _loc3_.length)
            {
               _loc4_ = _loc3_[_loc6_] as PetBriefInfo;
               if(_loc4_.level == 100)
               {
                  _loc5_ = true;
                  break;
               }
               _loc6_++;
            }
         }
         if(!_loc5_)
         {
            _loc7_ = new Need100LevelPanel(this.startFight);
            _loc7_.showPanel();
            return;
         }
         this.startFight();
      }
      
      private function startFight() : void
      {
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFailed);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         var _loc1_:IPetFight = ServiceContainer.instance.getService(IPetFight) as IPetFight;
         if(!_loc1_.ifSatisfyFightCondition())
         {
            ModalDialogManager.getInstance().clearAll();
            return;
         }
         _loc1_.startFight(97);
      }
      
      private function onEnterFightFailed(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFailed);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
      }
      
      private function onFightEnd(param1:PetFightEvent) : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL,this.onEnterFightFailed);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END,this.onFightEnd);
         var _loc2_:IShowPanel = new MainPanel();
         _loc2_.showPanel();
      }
      
      public function showPanel() : void
      {
         this.teamService.refuseInvite(true);
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         SundriesClient.logEvent(905);
         if(this.checkShowBook())
         {
            ProgressFullSprite.show();
            ResScheduler.getResource("activityres/activity121220/abyssevilstorybook",function(param1:IShowPanel):void
            {
               ProgressFullSprite.close();
               param1.addEventListener(PanelEvent.REMOVED,onBookRemove);
               param1.showPanel();
               LocalStore.setValue(UserInfo.userName,true,firstShowKey);
            },"mmo.activity121220.abyssevil.StoryBook");
         }
         else
         {
            this.initShow();
         }
      }
      
      private function onBookRemove(param1:PanelEvent) : void
      {
         var _loc2_:IShowPanel = param1.target as IShowPanel;
         _loc2_.removeEventListener(PanelEvent.REMOVED,this.onBookRemove);
         this.initShow();
      }
      
      private function initShow() : void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(AbyssevilClient.CMD_GET_INFO,this.onGetInfo);
         AbyssevilClient.instance().getInfo();
      }
      
      private function onGetInfo(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener(AbyssevilClient.CMD_GET_INFO,this.onGetInfo);
         ProgressFullSprite.close();
         this.leftTimes = 5 - (param1.params.dcc as int);
         this.state = param1.params.st as int;
         this.updatePanel();
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this,AlignType.NONE);
      }
      
      private function updatePanel() : void
      {
         var _loc1_:MovieClip = null;
         var _loc2_:MovieClip = null;
         var _loc3_:MovieClip = null;
         this.leftTimeTxt.text = this.leftTimes.toString();
         var _loc4_:int = 0;
         while(_loc4_ < 3)
         {
            _loc1_ = this.bossMcs[_loc4_] as MovieClip;
            _loc2_ = this.lightMcs[_loc4_] as MovieClip;
            _loc3_ = this.winTipMcs[_loc4_] as MovieClip;
            TipsManager.getInstance().removeTips(_loc1_);
            if(_loc4_ < this.state)
            {
               _loc1_.filters = null;
               _loc2_.visible = false;
               _loc2_.stop();
               _loc3_.visible = true;
            }
            else if(_loc4_ == this.state)
            {
               _loc1_.filters = null;
               _loc2_.visible = true;
               _loc2_.play();
               _loc3_.visible = false;
            }
            else
            {
               DisplayUtil.applyGray(_loc1_);
               if(_loc4_ == 1)
               {
                  TipsManager.getInstance().addTips(_loc1_,"只有战胜暗之魔魂才能开启挑战！");
               }
               else if(_loc4_ == 2)
               {
                  TipsManager.getInstance().addTips(_loc1_,"只有战胜龙之魔魂才能开启挑战！");
               }
               _loc2_.visible = false;
               _loc2_.stop();
               _loc3_.visible = false;
            }
            _loc4_++;
         }
         TipsManager.getInstance().removeTips(this.challengeBtn);
         TipsManager.getInstance().removeTips(this.evoBtn);
         if(this.state < 3)
         {
            this.challengeBtn.visible = true;
            if(this.leftTimes <= 0)
            {
               DisplayUtil.applyGray(this.challengeBtn);
               this.challengeBtn.enabled = false;
               TipsManager.getInstance().addTips(this.challengeBtn,"你今天已经没有挑战次数了哦！");
            }
            else
            {
               this.challengeBtn.filters = null;
               this.challengeBtn.enabled = true;
            }
            this.evoBtn.visible = false;
         }
         if(this.state == 3)
         {
            this.challengeBtn.visible = false;
            this.evoBtn.visible = true;
            this.evoBtn.enabled = true;
         }
         else if(this.state >= 4)
         {
            this.challengeBtn.visible = false;
            this.evoBtn.visible = true;
            this.evoBtn.enabled = false;
            DisplayUtil.applyGray(this.evoBtn);
            this.leftTimeTxt.text = "0";
            TipsManager.getInstance().addTips(this.evoBtn,"你已经召唤并获得了赤翼魔龙王！");
         }
      }
      
      private function checkShowBook() : Boolean
      {
         var _loc1_:Boolean = LocalStore.getValue(UserInfo.userName,this.firstShowKey) as Boolean;
         return !_loc1_;
      }
   }
}

