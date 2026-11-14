package mmo.superevolution
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.system.ApplicationDomain;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.item.IItemService;
   import mmo.interfaces.material.item.Item;
   import mmo.interfaces.material.item.UserItem;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetDataServiceEvent;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.revival.RIcon;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.revival.RLog;

   /**
    * One 超进化 (the 2015 module's EvoPanel on the 2013 libraries): the 亚比 it comes from (放入亚比
    * chooses one of the bag, 获得 opens its page of the 图鉴), what it takes, the 亚比 it becomes, and
    * 启动超进化 once everything is there. The rules on the art (60级, back to 1级, 学习力 cleared,
    * 天赋 and 性格 kept) are what the server does (superevo.ts). The 2015 "+" by the crystals opened
    * the later 商城; in 2013 they came from the 许愿图腾 of 蓝宝石要塞, as their 2013 descriptions say.
    */
   public class EvoPanel extends Sprite
   {
      public var cijiIcon:MovieClip;
      public var btnPet:SimpleButton;
      public var chaoIcon:MovieClip;
      public var jinhuaTxt:TextField;
      public var btnClose:SimpleButton;
      public var btnStart:SimpleButton;
      public var btnBuy265:SimpleButton;
      public var cijiTxt:TextField;
      public var view0:ItemView;
      public var btnGetPet:SimpleButton;
      public var view1:ItemView;
      public var view2:ItemView;
      public var iconHolder:MovieClip;
      public var btnBuy266:SimpleButton;
      public var view3:ItemView;
      public var selectPetMC:MovieClip;

      private var evoId:int;
      private var callBack:Function;
      private var cur:PetBriefInfo;

      public function EvoPanel(evoId:int, callBack:Function)
      {
         super();
         this.evoId = evoId;
         this.callBack = callBack;
         addView();
         refreshItem();
         refreshItemView();
         addEventListener(MouseEvent.CLICK, clickBtn);
         DisplayUtil.applyGray(btnStart);
         btnStart.mouseEnabled = false;
         SocketClient.instance.addEventListener("onAmountUpdated", onAmount);
         addEventListener(Event.REMOVED_FROM_STAGE, dispose);
      }

      private function onAmount(e:SocketClientEvent):void
      {
         refreshItem();
         refreshItemView();
         if (cur != null) checkBtnState();
      }

      private function clickBtn(e:MouseEvent):void
      {
         var name:String = e.target is DisplayObject ? DisplayObject(e.target).name : "";
         if (name == "btnClose") closePanel();
         else if (name == "btnStart") goEvo();
         else if (name == "btnPet") new ChoosePetPanel(SuperEvolutionConfig.getEvoNeedPetIdMatch(evoId), showPetByPetInfo).showPanel();
         else if (name == "btnGetPet") SuperEvolutionPanel.showDicPage(SuperEvolutionConfig.fromRace(evoId));
         else if (name.indexOf("btnBuy") == 0) SuperEvolutionPanel.whereFrom(int(name.substr(6)));
      }

      private function showPetByPetInfo(p:PetBriefInfo):void
      {
         if (cur != null && cur.id == p.id) return;
         cur = p;
         DisplayUtil.clearFilters(selectPetMC);
         checkBtnState();
      }

      private function goEvo():void
      {
         if (cur == null) return;
         if (cur.level < 60)
         {
            NewDialog.showFailMessage("你的亚比还没有达到60级，不能进行超进化哦！");
            return;
         }
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(MyClient.cmdEEvolution4shape, onEvolution);
         MyClient.evolution(cur.id, SuperEvolutionConfig.evoType(evoId));
      }

      private function onEvolution(e:SocketClientEvent):void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(MyClient.cmdEEvolution4shape, onEvolution);
         if (int(e.params.res) != 0)
         {
            NewDialog.showFailMessage(e.params.msg ? String(e.params.msg) : "进化失败！");
            return;
         }
         refreshItem();
         refreshItemView();
         ProgressFullSprite.show();
         var data:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         data.addEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM, onUpdate);
         PetClient.instance.viewSinglePM(cur.id);
      }

      private function onUpdate(e:PetDataServiceEvent):void
      {
         ProgressFullSprite.close();
         IPetDataService(e.currentTarget).removeEventListener(PetDataServiceEvent.RSPN_VIEW_SINGLE_PM, onUpdate);
         // The bag's numbers (level 1, the new race) for the panels that show them.
         try { PetClient.instance.viewAllPM(); } catch (err:Error) {}
         new EvolutionMovie(cur.viewId, evoId).show();
         clearSelectPet();
      }

      private function clearSelectPet():void
      {
         DisplayUtil.applyGray(selectPetMC);
         cur = null;
         DisplayUtil.applyGray(btnStart);
         btnStart.mouseEnabled = false;
      }

      private function checkBtnState():void
      {
         var all:Boolean = cur != null;
         for (var i:int = 0; i < 4 && all; i++)
         {
            var v:ItemView = getChildByName("view" + i) as ItemView;
            if (v != null && !v.ifEnough) all = false;
         }
         if (all)
         {
            DisplayUtil.clearFilters(btnStart);
            btnStart.mouseEnabled = true;
         }
         else
         {
            DisplayUtil.applyGray(btnStart);
            btnStart.mouseEnabled = false;
         }
      }

      private function addView():void
      {
         selectPetMC.gotoAndStop(SuperEvolutionConfig.ART_ORDER.indexOf(evoId) + 1);
         DisplayUtil.applyGray(selectPetMC);
         var icon:PetIconContainer = RIcon.container(evoId, PetIconType.LARGE, false);
         icon.addEventListener(PetIconEvent.ON_ICON_LOADED, loadIcon);
         icon.startLoad();
      }

      private function loadIcon(e:PetIconEvent):void
      {
         var icon:PetIconContainer = PetIconContainer(e.currentTarget);
         icon.removeEventListener(PetIconEvent.ON_ICON_LOADED, loadIcon);
         icon.mouseEnabled = icon.mouseChildren = false;
         iconHolder.addChild(icon);
         DisplayUtil.stop(icon);
         DisplayUtil.scaleDisplay(icon, 250, 250);
         DisplayUtil.middleDisplay(icon, 250, 240);
      }

      private function refreshItemView():void
      {
         var need:Array = SuperEvolutionConfig.EVO_ITEM_MATCH[evoId] || [];
         for (var i:int = 0; i < 4; i++)
         {
            var v:ItemView = getChildByName("view" + i) as ItemView;
            if (v != null) v.setView(need[i]);
         }
      }

      private function refreshItem():void
      {
         cijiTxt.text = String(SuperEvolutionPanel.count(265));
         cijiTxt.mouseEnabled = false;
         jinhuaTxt.text = String(SuperEvolutionPanel.count(266));
         jinhuaTxt.mouseEnabled = false;
      }

      public function showPanel():void
      {
         ModalDialogManager.getInstance().addModalDialogWithChangLayer(this);
      }

      private function closePanel():void
      {
         if (callBack != null) callBack();
         ModalDialogManager.getInstance().removeModalDialog(this);
      }

      private function dispose(e:Event = null):void
      {
         removeEventListener(Event.REMOVED_FROM_STAGE, dispose);
         removeEventListener(MouseEvent.CLICK, clickBtn);
         SocketClient.instance.removeEventListener("onAmountUpdated", onAmount);
      }
   }
}
