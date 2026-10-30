package mmo.scene.toolshop
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.common.DisplayUtil;
   import mmo.common.ProgressFullSprite;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.statistic.SundriesClient;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceContainerEvent;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.arrowguide.IArrowGuideService;
   import mmo.interfaces.catalog.IBconfigReaderService;
   import mmo.interfaces.catalog.IBookClubService;
   import mmo.interfaces.game.GameTable;
   import mmo.interfaces.game.IGameManager;
   import mmo.interfaces.rmbshoppingmall.IRmbShoppingMall;
   import mmo.interfaces.scenearrow.ISceneArrowService;
   import mmo.interfaces.shoot.IShootService;
   import mmo.interfaces.task.ITaskService;
   import mmo.interfaces.task.TaskEvent;
   import mmo.interfaces.task.TaskEventDispatcher;
   import mmo.play.scene.SceneBase;
   
   /**
    * LATER scene/toolshop (道具店, the live client's code of the copy uploaded
    * in 2016, decompiled), compiled against the 2013 interfaces and put back
    * on that copy's art (tools/swf_transplant.py): the 2013 scene is lost.
    * One call the 2013 SceneArrowService does not have (removeArrowsByGroup)
    * is left out, so the 奥拉道具册 opens.
    */
   public class Toolshop extends SceneBase
   {
      
      private static const catalogNo:String = "catalog201001";
      
      private static const catalogNo2:String = "catalog201005";
      
      private static const catalogNo3:String = "catalog201006";
      
      private static const catalogNo4:String = "catalog201110";
      
      public var background:MovieClip;
      
      public var overlap:MovieClip;
      
      public var topground:MovieClip;
      
      public var foreground:MovieClip;
      
      public var obstruction:MovieClip;
      
      private var arrow:MovieClip;
      
      private var shootService:IShootService;
      
      private var mc_showCatalog:SimpleButton;
      
      private var bService:IBconfigReaderService = null;
      
      private var arrowguide:IArrowGuideService = ServiceContainer.getService("ArrowGuideService") as IArrowGuideService;
      
      private var btnYaBi:SimpleButton;
      
      private var btnHuoLi:SimpleButton;
      
      private var btnTiLi:SimpleButton;
      
      private var mcMechanicalArm:MovieClip;
      
      private var sceneArrow:ISceneArrowService = ServiceContainer.instance.getService(ISceneArrowService) as ISceneArrowService;
      
      internal var taskService:ITaskService = ServiceContainer.getService(ITaskService) as ITaskService;
      
      public function Toolshop()
      {
         super(500,350);
         this.addInitLocation("startotool",new Point(500,400));
         this.addInitLocation("fromstarshopping",new Point(720,420));
         TipsManager.getInstance().addTips(this.foreground.et2,"流星购物街");
         this.bService = ServiceContainer.getService(IBconfigReaderService) as IBconfigReaderService;
         this.mc_showCatalog = this.background.getChildByName("showBtnCatalog") as SimpleButton;
         this.mc_showCatalog.addEventListener(MouseEvent.CLICK,this.btnCatalogClick);
         TipsManager.getInstance().addTips(this.mc_showCatalog,"奥拉道具册");
         this.btnYaBi = this.background.getChildByName("btnYabi") as SimpleButton;
         this.btnHuoLi = this.background.getChildByName("btnHuoLi") as SimpleButton;
         this.btnTiLi = this.background.getChildByName("btnTiLi") as SimpleButton;
         this.btnYaBi.addEventListener(MouseEvent.CLICK,this.onClickYabi);
         this.btnYaBi.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
         this.btnYaBi.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
         this.btnTiLi.addEventListener(MouseEvent.CLICK,this.onClickTiLi);
         this.btnTiLi.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
         this.btnTiLi.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
         this.btnHuoLi.addEventListener(MouseEvent.CLICK,this.onClickHuoLi);
         this.btnHuoLi.addEventListener(MouseEvent.MOUSE_OVER,this.onMouseOver);
         this.btnHuoLi.addEventListener(MouseEvent.MOUSE_OUT,this.onMouseOut);
         SimpleButton(this.background.btnShouFei).addEventListener(MouseEvent.CLICK,this.onClickShouFei);
         TipsManager.getInstance().addTips(this.btnYaBi,"亚比球售卖");
         TipsManager.getInstance().addTips(this.btnTiLi,"体力糖售卖");
         TipsManager.getInstance().addTips(this.btnHuoLi,"活力豆售卖");
         TipsManager.getInstance().addTips(this.background.btnShouFei,"精品道具");
         TipsManager.getInstance().addTips(SimpleButton(this.background.getChildByName("btnBuyBack")),"兜兜回收器");
         TipsManager.getInstance().addTips(SimpleButton(this.background.getChildByName("btnBuyEgg")),"亚比蛋售卖专柜");
         TipsManager.getInstance().addTips(SimpleButton(this.background.btnShootCard),"射击卡售卖");
         SimpleButton(this.background.getChildByName("btnBuyBack")).addEventListener(MouseEvent.CLICK,this.onBuyBack);
         SimpleButton(this.background.getChildByName("btnBuyEgg")).addEventListener(MouseEvent.CLICK,this.onBuyEgg);
         SimpleButton(this.background.btnShootCard).addEventListener(MouseEvent.CLICK,this.onBuyShootCard);
         SimpleButton(this.background.getChildByName("btnGame")).addEventListener(MouseEvent.CLICK,this.onClickGame);
         TaskEventDispatcher.instance.addEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         this.mcMechanicalArm = this.backGround.getChildByName("mechanicalarm") as MovieClip;
      }
      
      private function onMouseOut(param1:MouseEvent) : void
      {
         this.mcMechanicalArm.visible = true;
         this.mcMechanicalArm.play();
      }
      
      private function onMouseOver(param1:MouseEvent) : void
      {
         this.mcMechanicalArm.stop();
         this.mcMechanicalArm.visible = false;
      }
      
      private function onBuyShootCard(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         this.showCatalog(catalogNo4,"4");
      }
      
      private function onBuyEgg(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         evt.stopImmediatePropagation();
         SundriesClient.logButton(271);
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("RmbShoppingMallService",function(param1:IRmbShoppingMall, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showRmbShoppingPanel(1);
         });
      }
      
      private function onClickGame(param1:MouseEvent) : void
      {
         var evt:MouseEvent = param1;
         ServiceContainer.instance.tryGetService(IGameManager,function(param1:IGameManager, param2:Object):void
         {
            param1.showGame(GameTable.GAME_MATCH_THREE);
         });
      }
      
      private function onBuyBack(param1:MouseEvent) : void
      {
         if(param1 != null)
         {
            param1.stopImmediatePropagation();
         }
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("EVENT_ONOPEN_DDHSQ",{}));
         var _loc2_:ISceneArrowService = ServiceContainer.getService(ISceneArrowService) as ISceneArrowService;
         _loc2_.removeArrow("toolshop_ci_doudoubuyback");
         ServiceContainer.instance.addEventListener(ServiceContainerEvent.onGetService,this.onGetBuyBack);
         ServiceContainer.instance.tryGetService("StuffBuyBack");
      }
      
      private function onGetBuyBack(param1:ServiceContainerEvent) : void
      {
         if(param1.serviceName != "StuffBuyBack")
         {
            return;
         }
         ServiceContainer.instance.removeEventListener(ServiceContainerEvent.onGetService,this.onGetBuyBack);
         (param1.service as IShowPanel).showPanel();
      }
      
      private function btnCatalogClick(param1:MouseEvent) : void
      {
         param1.stopImmediatePropagation();
         // REBUILT: removeArrowsByGroup is not in the 2013 ISceneArrowService.
         SundriesClient.logButton(273);
         this.showCatalog(catalogNo,"10");
         this.bService.setRead(catalogNo);
      }
      
      private function onAction(param1:TaskEvent) : void
      {
         if(param1.params.action == "menu_tool_catalog")
         {
            this.showCatalog(catalogNo,"11");
         }
         else if(param1.params.action == "menu_goods_buyback")
         {
            this.onBuyBack(null);
         }
      }
      
      private function showCatalog(param1:String, param2:String) : void
      {
         var cataloNum:String = param1;
         var logKey:String = param2;
         var onGetCatalogService:Function = function(param1:IBookClubService, param2:Object):void
         {
            param1.openLog(logKey);
            param1.showPage(cataloNum);
         };
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService,onGetCatalogService,this);
      }
      
      override protected function onJoinRoom() : void
      {
         SundriesClient.logEvent(16935);
         addEntrances(this.foreground.getChildByName("et2"),"starshopping","fromtoolshop");
      }
      
      private function onClickYabi(param1:MouseEvent) : void
      {
         var onGetCatalogService:Function;
         var e:MouseEvent = param1;
         e.stopImmediatePropagation();
         SundriesClient.logButton(268);
         onGetCatalogService = function(param1:IBookClubService, param2:Object):void
         {
            param1.openLog("5");
            param1.showPageBy2Index(catalogNo,3,1);
         };
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService,onGetCatalogService,this);
      }
      
      private function onClickTiLi(param1:MouseEvent) : void
      {
         var onGetCatalogService:Function;
         var e:MouseEvent = param1;
         e.stopImmediatePropagation();
         SundriesClient.logButton(270);
         onGetCatalogService = function(param1:IBookClubService, param2:Object):void
         {
            param1.openLog("7");
            param1.showPageBy2Index(catalogNo,2,1);
         };
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService,onGetCatalogService,this);
      }
      
      private function onClickHuoLi(param1:MouseEvent) : void
      {
         var onGetCatalogService:Function;
         var e:MouseEvent = param1;
         e.stopImmediatePropagation();
         SundriesClient.logButton(269);
         onGetCatalogService = function(param1:IBookClubService, param2:Object):void
         {
            param1.openLog("6");
            param1.showPageBy2Index(catalogNo,2,2);
         };
         ServiceContainer.instance.tryGetService(ServiceNames.SellBookService,onGetCatalogService,this);
      }
      
      private function onClickShouFei(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         e.stopImmediatePropagation();
         this.sceneArrow.removeArrow("toolshop_spectoolbook");
         SundriesClient.logButton(275);
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService("RmbShoppingMallService",function(param1:IRmbShoppingMall, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showRmbShoppingPanel(2);
         });
      }
      
      override protected function onLeaveRoom() : void
      {
         super.onLeaveRoom();
         TaskEventDispatcher.instance.removeEventListener(TaskEvent.ON_TASK_ACTION,this.onAction);
         if(this.arrow != null)
         {
            DisplayUtil.stopAndRemove(this.arrow);
         }
      }
   }
}

