package mmo.robot.robotitem
{
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.panel.floatpanel.FloatPanelManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.viewloader.ViewLoader;
   import mmo.framework.comm.RobotClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.clothes.Clothes;
   import mmo.interfaces.material.clothes.ClothesParts;
   import mmo.interfaces.material.robot.IRobotItemService;
   import mmo.interfaces.material.robot.UserRobotItem;
   import mmo.interfaces.material.robotclothes.IRobotClothesService;
   import mmo.interfaces.material.robotclothes.UserRobotClothes;
   import mmo.interfaces.robot.robotpanel.RobotPanelEvent;
   import mmo.interfaces.robot.robotpanel.RobotPanelEventDispatcher;
   import mmo.revival.RLog;
   import mmo.robot.robotitem.robotmaterial.FeedMaterial;
   import mmo.robot.robotitem.robotmaterial.RobotItemView;
   import mmo.util.component.page.PageComponent;
   import mmo.util.component.page.PageComponentEvent;

   /**
    * The HELLO物品 panel (the 2016 copy's symbol 36): nine squares a page.
    *   普通物品 (normalBtn)   营养饼干 first (RobotClient.addEnergy, 2-18), then the
    *                           HELLO's 道具 (RobotItemService; a click uses one, 2-5 {ii})
    *   HELLO服装 (helloCloth) the HELLO's clothes, worn with a click (2-17 {clothId})
    *   蓝宝石 (vipBtn)        the same, for a 蓝宝石 member (the 2016 RobotClothView: only
    *                           members dress their HELLO)
    */
   public class RobotItemPanel extends Sprite implements IDispose
   {
      private static var _instance:RobotItemPanel;
      private static const PER_PAGE:int = 9;

      public var vipBtn:MovieClip;
      public var pageTxt:TextField;
      public var btnClose:SimpleButton;
      public var ct:MovieClip;
      public var normalBtn:MovieClip;
      public var prevBtn:SimpleButton;
      public var nextBtn:SimpleButton;
      public var helloCloth:MovieClip;

      private var page:PageComponent;
      private var kind:int = 0;
      private var list:Array = [];

      public function RobotItemPanel()
      {
         super();
         _instance = this;
      }

      public static function get instance():RobotItemPanel
      {
         return _instance;
      }

      public function initPanel(host:Sprite):void
      {
         for each (var tab:MovieClip in [normalBtn, helloCloth, vipBtn])
         {
            if (tab == null) continue;
            tab.buttonMode = true;
            tab.mouseChildren = false;
            tab.addEventListener(MouseEvent.CLICK, onTab);
         }
         if (btnClose) btnClose.addEventListener(MouseEvent.CLICK, onClose);
         RobotPanelEventDispatcher.getInstance().addEventListener(RobotPanelEvent.CLOSEROBOTMESPANEL, onRobotMesClosed);
         RobotPanelEventDispatcher.getInstance().addEventListener(RobotPanelEvent.UPDATEITEM, onUpdate);
         SocketClient.instance.addEventListener(RobotClient.cmdChangeRobotAvatar, onAvatarChanged);
         SocketClient.instance.addEventListener(RobotClient.cmdAddEnergy, onFed);
         showPage(0);
      }

      public function show():void
      {
         FloatPanelManager.getInstance().addFloatPanel(this, 545, 67, null, 1);
      }

      /** 0 普通物品, 1 HELLO服装, 2 蓝宝石 HELLO服装. */
      public function showPage(k:int):void
      {
         kind = k;
         var tabs:Array = [normalBtn, helloCloth, vipBtn];
         for (var i:int = 0; i < tabs.length; i++) if (tabs[i]) MovieClip(tabs[i]).gotoAndStop(i == k ? 2 : 1);
         list = k == 0 ? items() : clothes(k == 2);
         if (page == null)
         {
            page = new PageComponent(list, PER_PAGE, prevBtn, nextBtn, pageTxt);
            page.addEventListener(PageComponentEvent.ON_PAGE_CHANGE, function(e:PageComponentEvent):void { draw(); });
         }
         else page.updateData(list);
         draw();
      }

      private function items():Array
      {
         var out:Array = [{feed: true}];
         try
         {
            var svc:IRobotItemService = ServiceContainer.getService("RobotItemService") as IRobotItemService;
            for each (var u:UserRobotItem in Object(svc).getMyMaterials()) if (u.quantity > 0) out.push(u);
         }
         catch (e:Error) { RLog.error("robotitem items", e); }
         return out;
      }

      private function clothes(vip:Boolean):Array
      {
         var out:Array = [];
         try
         {
            var svc:IRobotClothesService = ServiceContainer.getService("RobotClothesService") as IRobotClothesService;
            for each (var c:UserRobotClothes in svc.getMyRobotClothes())
            {
               var isVip:Boolean = c.material != null && c.material.vip;
               // HELLO服装: all of them; the 蓝宝石 page: the members' ones (every 2013 HELLO outfit is).
               if (!vip || isVip) out.push(c);
            }
         }
         catch (e:Error) { RLog.error("robotitem clothes", e); }
         return out;
      }

      private function draw():void
      {
         while (ct.numChildren > 0) ct.removeChildAt(0);
         var shown:Array = page.getCurrentPageData();
         for (var i:int = 0; i < shown.length; i++)
         {
            var d:DisplayObject = kind == 0 ? itemView(shown[i]) : clothView(shown[i] as UserRobotClothes);
            if (d == null) continue;
            d.x = int(i % 3) * 80;
            d.y = int(i / 3) * 60;
            ct.addChild(d);
         }
      }

      private function itemView(o:Object):DisplayObject
      {
         if (o is UserRobotItem) return new RobotItemView(o as UserRobotItem);
         var feed:FeedMaterial = new FeedMaterial();
         feed.name = "helloFeed";
         TipsManager.getInstance().addComplexTips(feed, "营养饼干", "HELLO饿的时候最喜欢吃的营养饼干，可以补充HELLO的能量。");
         feed.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { RobotClient.instance.addEnergy(); });
         return feed;
      }

      private function clothView(c:UserRobotClothes):DisplayObject
      {
         var box:Sprite = new Sprite();
         var cl:Clothes = c.material as Clothes;
         try
         {
            var part:ClothesParts = cl.parts[0] as ClothesParts;
            var v:DisplayObject = ViewLoader.instance.getViewCustom(part.clothesNo + "_A", "skinicon/" + cl.fileName, 45, 45);
            v.x = 5;
            v.y = 3;
            box.addChild(v);
         }
         catch (e:Error) { RLog.error("robotitem cloth view", e); }
         box.graphics.beginFill(0, 0);
         box.graphics.drawRect(0, 0, 56, 52);
         box.graphics.endFill();
         var member:Boolean = MemberManager.instance.isMember();
         if (member)
         {
            box.buttonMode = true;
            box.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
            {
               RobotClient.instance.changeRobotAvatar(c.materialId);
            });
         }
         else DisplayUtil.applyGray(box);
         TipsManager.getInstance().addComplexTips(box, cl ? cl.name : "", member ? (cl && cl.description ? cl.description : "") : "只有蓝宝骑士才可以给HELLO换装哦！");
         return box;
      }

      private function onTab(e:MouseEvent):void
      {
         showPage(e.currentTarget == normalBtn ? 0 : e.currentTarget == helloCloth ? 1 : 2);
      }

      private function onUpdate(e:RobotPanelEvent):void
      {
         showPage(kind);
      }

      private function onAvatarChanged(e:SocketClientEvent):void
      {
         if (e.params.result) NewDialog.showSucceedMessage("HELLO换上新衣服啦！");
         RobotClient.instance.getRobot();
         showPage(kind);
      }

      private function onFed(e:SocketClientEvent):void
      {
         if (int(e.params.res) == 1) NewDialog.showSucceedMessage("HELLO吃得饱饱的，能量满满！");
         else NewDialog.showFailMessage(e.params.msg ? String(e.params.msg) : "HELLO现在饱饱的，一点儿也不饿哦！");
         RobotClient.instance.getRobot();
      }

      private function onRobotMesClosed(e:RobotPanelEvent):void
      {
         close();
      }

      private function onClose(e:MouseEvent):void
      {
         close();
      }

      private function close():void
      {
         FloatPanelManager.getInstance().removeFloatPanel(this);
         dispose();
      }

      public function dispose():void
      {
         RobotPanelEventDispatcher.getInstance().removeEventListener(RobotPanelEvent.CLOSEROBOTMESPANEL, onRobotMesClosed);
         RobotPanelEventDispatcher.getInstance().removeEventListener(RobotPanelEvent.UPDATEITEM, onUpdate);
         SocketClient.instance.removeEventListener(RobotClient.cmdChangeRobotAvatar, onAvatarChanged);
         SocketClient.instance.removeEventListener(RobotClient.cmdAddEnergy, onFed);
         if (_instance == this) _instance = null;
      }
   }
}
