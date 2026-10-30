package mmo.map
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.display.Shape;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.system.LoaderContext;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import mmo.config.ConfigReader;
   import mmo.interfaces.IService;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.houseinterfaces.IHouseService;
   import mmo.framework.comm.SocketClient;
   import mmo.loader.CustomLoader;
   import mmo.loader.layer.LayerManager;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REBUILT map/map (mmo.map.AolaMapService, opened by scenes and the control
    * bar with SimpleCustomLoader.loadSingleResource("map/map",
    * "mmo.map.AolaMapService", ...).showPanel()).
    *
    * The January 2013 map/map.swf is lost; the live one is a 2026 redesign.
    * The artwork shown here is the world map of 30 November 2012 that 百田
    * published on its own guide page (aola.100bt.com/xinshouybdt/52097.html,
    * img2.a0bi.com/upload/old/web/1354946686227_.swf), installed as
    * map/mapguide2012.swf. Its own timeline pages between 奥拉星 and the
    * galaxies; every place on it is a button named btn_<map name>, and the
    * map names are the ones in config.xml <map> (nm -> room rm), so a click
    * goes to the same room the 2013 map sent players to.
    */
   public class AolaMapService extends EventDispatcher implements IShowPanel
   {
      private static const ART:String = "map/mapguide2012";
      private static const W:int = 736;
      private static const H:int = 500;

      private static var _panel:Sprite;
      private static var _art:DisplayObject;
      private static var _loader:Loader;

      public function AolaMapService()
      {
         super();
      }

      public function showPanel():void
      {
         // Closed, the panel stays inside ModalDialogManager's container: only "on stage" means open.
         if (_panel != null && _panel.stage != null) return;
         if (_panel == null) buildPanel();
         ModalDialogManager.getInstance().addModalDialog(_panel);
         if (_art == null && _loader == null) loadArt();
      }

      private function buildPanel():void
      {
         _panel = new Sprite();
         var bg:Shape = new Shape();
         bg.graphics.lineStyle(3, 0x6FC8FF);
         bg.graphics.beginFill(0x050A24);
         bg.graphics.drawRoundRect(-6, -6, W + 12, H + 12, 18, 18);
         bg.graphics.endFill();
         _panel.addChild(bg);
         var wait:TextField = new TextField();
         wait.name = "wait";
         wait.defaultTextFormat = new TextFormat("SimSun", 14, 0xFFFFFF);
         wait.selectable = false;
         wait.width = 200;
         wait.text = "正在打开地图……";
         wait.x = (W - 100) / 2;
         wait.y = H / 2 - 10;
         _panel.addChild(wait);
         _panel.addChild(closeButton());
         _panel.scrollRect = null;
      }

      private function closeButton():Sprite
      {
         var b:Sprite = new Sprite();
         b.name = "closeBtn";
         b.buttonMode = true;
         b.graphics.lineStyle(2, 0xFFFFFF);
         b.graphics.beginFill(0xD9452B);
         b.graphics.drawCircle(0, 0, 13);
         b.graphics.endFill();
         b.graphics.lineStyle(3, 0xFFFFFF);
         b.graphics.moveTo(-5, -5);
         b.graphics.lineTo(5, 5);
         b.graphics.moveTo(5, -5);
         b.graphics.lineTo(-5, 5);
         b.x = W - 4;
         b.y = 4;
         b.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { close(); });
         return b;
      }

      private function loadArt():void
      {
         _loader = new Loader();
         // Own domain: the guide's classes (mc1..mc7, btnr) must not meet the game's.
         var ctx:LoaderContext = new LoaderContext(false, new ApplicationDomain());
         _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onArt);
         _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
         {
            RLog.error("map", "art missing: " + ART + " " + e.text);
            _loader = null;
            var wait:TextField = _panel.getChildByName("wait") as TextField;
            if (wait) wait.text = "地图载入失败";
         });
         _loader.load(CustomLoader.getVerURLRequest(ART), ctx);
      }

      private function onArt(e:Event):void
      {
         _art = _loader;
         var wait:DisplayObject = _panel.getChildByName("wait");
         if (wait) _panel.removeChild(wait);
         _art.scrollRect = new Rectangle(0, 0, W, H);
         _panel.addChildAt(_art, 1);
         // Capture phase: decide before the guide's own timeline handlers run.
         _panel.addEventListener(MouseEvent.CLICK, onClick, true);
      }

      private function onClick(e:MouseEvent):void
      {
         var t:DisplayObject = e.target as DisplayObject;
         while (t != null && t != _panel && !(t is SimpleButton && t.name.indexOf("btn_") == 0))
         {
            t = t.parent;
         }
         if (t == null || t == _panel) return;
         var nm:String = t.name.substr(4);
         var room:String = roomFor(nm);
         e.stopImmediatePropagation();
         RLog.log("map: " + nm + " -> " + room);
         if (nm == "home")
         {
            close();
            goHome();
            return;
         }
         if (room == null)
         {
            RNotice.show(LayerManager.getBaseTop(), "这个地方还没有开放哦！");
            return;
         }
         close();
         SceneManager.getInstance().loadScene(room);
      }

      /** As the 2013 arrow guide does: HouseService.houseLoader.loadHouse(my name). */
      public static function goHome():void
      {
         ServiceContainer.instance.tryGetService(ServiceNames.HouseService, function(svc:IService, o:Object):void
         {
            var house:IHouseService = svc as IHouseService;
            if (house == null || house.houseLoader == null)
            {
               RNotice.show(LayerManager.getBaseTop(), "小屋还在修复中，敬请期待！");
               return;
            }
            house.houseLoader.loadHouse(SocketClient.instance.myUserName);
         });
      }

      /** config.xml <map><m nm rm/></map>; names that are rooms themselves pass through. */
      public static function roomFor(nm:String):String
      {
         var cfg:ConfigReader = ConfigReader.instance;
         var xml:XML = cfg.xmlDocument;
         if (xml != null)
         {
            var hit:XMLList = xml.map.m.(@nm == nm);
            if (hit.length() > 0)
            {
               var rm:String = String(hit[0].@rm);
               if (cfg.getSceneSwf(rm) != null) return rm;
            }
         }
         return cfg.getSceneSwf(nm) != null ? nm : null;
      }

      public function close():void
      {
         if (_panel != null && _panel.stage != null)
         {
            ModalDialogManager.getInstance().removeModalDialog(_panel);
         }
      }
   }
}
