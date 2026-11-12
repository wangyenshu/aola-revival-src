package mmo.bosspanel.shikarsky
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.AlignType;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.user.UserInfo;
   import mmo.common.utils.panel.PanelEffect;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.honour.IHonourService;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.task.ITaskNpcService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.interfaces.team.ITeamService;

   /**
    * dailyactivity/bosspanel/shikarskybosspanel (守护者之战 猎空, August 2013; the copy of the live
    * CDN) on the 2013 libraries (aola-revival): its decompiled code on its own art. 开始挑战 fights
    * 猎空's three forms one after another (PetExtension 54_16, 31697, 21697, 11697); after each of
    * the first two won, 猎空 speaks (boss11697win, boss21697win, as NPC 1064) and its answer goes
    * on to the next. 已战胜 shows once 54_19's list holds 1695 (猎空 beaten). Its 背包, 治疗 and 远程仓库
    * open the 2013 services (the later PetFunctionShortcut is not in the 2013 libraries); its logs
    * (SundriesClient) are left out.
    */
   public class ShikarSkyBossPanel extends Sprite implements IShowPanel, IDispose
   {
      public var btnBossInfo:SimpleButton;
      public var btnBuyEgg:SimpleButton;
      public var btnClose:SimpleButton;
      public var btnCure:SimpleButton;
      public var btnFight:SimpleButton;
      public var btnPackage:SimpleButton;
      public var btnStore:SimpleButton;
      public var mcWin:MovieClip;

      private const BOSS_EGG_ID:int = 1695;
      private const FIGHT_BOSS_ID:Array = [31697, 21697, 11697];
      private const NPC_TALK_NAMES:Array = ["boss11697win", "boss21697win"];
      private const NPC_ID:int = 1064;
      private const petExtendsion:String = "PetExtension";
      private const cmdGetPanelInfo:String = "54_19";

      private var CLICK_HANDLER:Object;
      private var currentFightIndex:int = 0;
      private var _mcWin:MovieClip;
      private var petFightService:IPetFight;
      private var taskNpcService:ITaskNpcService;

      public function ShikarSkyBossPanel()
      {
         this.CLICK_HANDLER = {
            "btnFight": this.startFight,
            "btnBossInfo": this.showBossInfo,
            "btnBadge": this.showHornor,
            "btnBuyEgg": this.showBuyEgg,
            "btnClose": this.closePanel,
            "btnPackage": this.showPackage,
            "btnStore": this.showStore,
            "btnCure": this.cure
         };
         super();
         this.init();
         this.addEventListener(MouseEvent.CLICK, this.onMouseClickListener);
      }

      private function init():void
      {
         this._mcWin = MovieClip(this.mcWin);
         this.petFightService = ServiceContainer.getService(IPetFight) as IPetFight;
         this.taskNpcService = ServiceContainer.getService(ITaskNpcService) as ITaskNpcService;
      }

      private function onMouseClickListener(e:MouseEvent):void
      {
         var name:String = e.target.name;
         if (this.CLICK_HANDLER.hasOwnProperty(name)) this.CLICK_HANDLER[name].apply();
      }

      private function showBossInfo():void
      {
         new BossInfoPanel().showPanel();
      }

      private function showPackage():void
      {
         open("NewPetPackage");
      }

      private function showStore():void
      {
         open("PetWareHouse");
      }

      private static function open(name:String):void
      {
         ServiceContainer.instance.tryGetService(name, function(svc:IService, o:Object = null):void
         {
            if (svc is IShowPanel) IShowPanel(svc).showPanel();
         });
      }

      private function cure():void
      {
         var data:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         if (data == null) return;
         if (data.checkPetIsEmpty())
         {
            NewDialog.showMessage("你的背包里没有亚比哦！");
            return;
         }
         if (data.checkAllPetHPIsFull() && data.checkAllPetPPIsFull())
         {
            NewDialog.showMessage("你背包里的亚比已经充满活力，不需要治疗哦！");
            return;
         }
         data.recureAllPet();
      }

      private function showHornor():void
      {
         var honour:IHonourService = ServiceContainer.instance.getService(IHonourService) as IHonourService;
         if (honour != null) honour.showPanel(UserInfo.userName);
      }

      private function showBuyEgg():void
      {
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService, function(svc:IBookClubService, o:Object):void
         {
            svc.openLog("132");
            svc.showPage("catalog201006");
         }, this);
      }

      private function getPanelInfo():void
      {
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(this.cmdGetPanelInfo, this.onGetPanelInfo);
         SocketClient.instance.sendXtMessage(this.petExtendsion, this.cmdGetPanelInfo, {});
      }

      private function onGetPanelInfo(e:SocketClientEvent):void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(this.cmdGetPanelInfo, this.onGetPanelInfo);
         var won:Boolean = false;
         for each (var mark:String in String(e.params.bo || "").split(","))
         {
            if (mark == this.BOSS_EGG_ID.toString())
            {
               won = true;
               break;
            }
         }
         if (this._mcWin != null) this._mcWin.visible = won;
         if (this.stage == null) ModalDialogManager.getInstance().addModalDialog(this, AlignType.NONE, PanelEffect.NONE, true, 0, 0, true);
      }

      private function startFight():void
      {
         var team:ITeamService = ServiceContainer.getService(ITeamService) as ITeamService;
         if (team != null && team.getMyTeam() != null)
         {
            NewDialog.showFailMessage("组队状态不能与boss对战！");
            return;
         }
         if (!this.petFightService.ifSatisfyFightCondition()) return;
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, this.onFightEnd);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.ENTER_FIGHT_FAIL, this.onEnterFightFail);
         this.petFightService.fightWithBoss(String(this.FIGHT_BOSS_ID[this.currentFightIndex]), this.currentFightIndex);
      }

      private function onEnterFightFail(e:PetFightEvent):void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END, this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL, this.onEnterFightFail);
      }

      private function onTaskAction(e:TaskEvent):void
      {
         if (e.params.action == "shikarSkyNextFight")
         {
            TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION, this.onTaskAction);
            ++this.currentFightIndex;
            this.startFight();
         }
      }

      private function onFightEnd(e:PetFightEvent):void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.FIGHT_END, this.onFightEnd);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.ENTER_FIGHT_FAIL, this.onEnterFightFail);
         if (e.isWin && this.currentFightIndex < this.NPC_TALK_NAMES.length)
         {
            TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION, this.onTaskAction);
            this.taskNpcService.showNpcPanelFreely(this.NPC_TALK_NAMES[this.currentFightIndex], this.NPC_ID);
            return;
         }
         this.resetAndShowPanel();
      }

      private function resetAndShowPanel():void
      {
         this.currentFightIndex = 0;
         this.showPanel();
      }

      private function closePanel():void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
      }

      public function showPanel():void
      {
         this.getPanelInfo();
      }

      public function dispose():void
      {
         SocketClient.instance.removeEventListener(this.cmdGetPanelInfo, this.onGetPanelInfo);
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION, this.onTaskAction);
      }
   }
}
