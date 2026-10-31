package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.external.ExternalInterface;
   import flash.text.TextField;
   import mmo.config.ConfigReader;
   import mmo.common.member.MemberManager;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.loader.layer.LayerManager;
   import mmo.play.scene.SceneManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;
   import mmo.revival.RTextEntry;

   /**
    * The revival's 工具箱 (not of 2013): add 晶币, 星币, 晶豆 and 亚比 experience
    * (to the first 亚比 of the bag), become 蓝宝石 or not, and get any 亚比 by its number at a chosen
    * level (to the bag, or to the 亚比仓库 when the bag is full), for testing
    * fights and for players who want them. Server: SundriesExtension.revival_toolbox.
    */
   public class ToolboxPanel extends Sprite
   {
      private static const W:int = 470;
      private static const H:int = 492;
      private static var current:ToolboxPanel;

      private var box:Sprite;
      private var totals:TextField;
      private var said:TextField;
      private var petName:TextField;
      private var raceIn:TextField;
      private var levelIn:TextField;
      private var sceneIn:TextField;
      private var vipButton:Sprite;
      private var vip:Boolean;

      public static function toggle():void
      {
         if (current != null && current.parent != null)
         {
            current.close();
            return;
         }
         current = new ToolboxPanel();
         LayerManager.getBaseTop().addChild(current);
      }

      /**
       * Keeps UserInfo.xingbi and the 蓝宝石 state as the server has them
       * (asked once at start, then from every toolbox reply). The 2013
       * client set up MemberManager from the lost login; here it is
       * MemberManager.init(open, privileges, services, member type 4 or 0,
       * vip level, vip score, annual, fop, hbm).
       */
      public static function watchMoney():void
      {
         SocketClient.instance.addEventListener("revival_toolbox", function(e:SocketClientEvent):void
         {
            UserInfo.xingbi = int(e.params.xingbi);
            setMember(e.params.vip == true);
         });
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_toolbox", {});
      }

      public static function setMember(v:Boolean):void
      {
         try { MemberManager.instance.init(true, "", [], v ? 4 : 0, v ? 1 : 0, 0, false, false, false); }
         catch (err:Error) { RLog.error("toolbox member", err); }
      }

      public function ToolboxPanel()
      {
         super();
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "工具箱", close, "toolboxClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         box.addChild(RUI.well(16, 54, W - 32, 196));
         totals = RUI.text(13, RUI.BLUE, true);
         totals.x = 30;
         totals.y = 62;
         box.addChild(totals);
         row("晶币", "score", "10000", 92);
         row("星币", "xingbi", "1000", 130);
         row("晶豆", "jingdou", "1000", 168);
         row("亚比经验", "exp", "10000", 206, "给背包里第一只亚比");

         vipButton = RUI.button("成为蓝宝石", function():void { send({vip: !vip}); }, 104, 24, 0x6CC0F5, 0x2E86D6, "toolboxVip");
         vipButton.x = W - 128;
         vipButton.y = 58;
         box.addChild(vipButton);
         box.addChild(RUI.well(16, 260, W - 32, 82));
         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = "领取亚比    编号";
         t.x = 30;
         t.y = 272;
         box.addChild(t);
         raceIn = RUI.input(56, "1", "0-9", 4, "toolboxRace");
         raceIn.x = 148;
         raceIn.y = 270;
         raceIn.addEventListener(Event.CHANGE, showName);
         box.addChild(raceIn);
         var l:TextField = RUI.text(14, RUI.BLUE, true);
         l.text = "等级";
         l.x = 214;
         l.y = 272;
         box.addChild(l);
         levelIn = RUI.input(40, "30", "0-9", 3, "toolboxLevel");
         levelIn.x = 252;
         levelIn.y = 270;
         box.addChild(levelIn);
         box.addChild(place(RUI.button("领取", getPet, 70, 26, 0xFFC45A, 0xF07812, "toolboxGetPet"), W - 106, 268));
         petName = RUI.text(13, 0x335577, false);
         petName.x = 30;
         petName.y = 304;
         box.addChild(petName);

         // 传送 to any place of config.xml, by its name (crossroad) or its
         // Chinese name (十字大道); 存档: the saves of this browser to a file and back.
         box.addChild(RUI.well(16, 350, W - 32, 84));
         var tl:TextField = RUI.text(14, RUI.BLUE, true);
         tl.text = "传送    地图";
         tl.x = 30;
         tl.y = 362;
         box.addChild(tl);
         sceneIn = RUI.input(150, "", null, 30, "toolboxScene");
         sceneIn.x = 118;
         sceneIn.y = 360;
         box.addChild(sceneIn);
         RTextEntry.attach(sceneIn, "传送到哪里？（地图名或中文名）", teleport);
         box.addChild(place(RUI.button("传送", teleport, 70, 26, 0xFFC45A, 0xF07812, "toolboxGo"), 280, 358));
         var hint:TextField = RUI.text(11, 0x557799, false);
         hint.text = "地图名或中文名";
         hint.x = 30;
         hint.y = 390;
         box.addChild(hint);
         var sl:TextField = RUI.text(14, RUI.BLUE, true);
         sl.text = "存档";
         sl.x = 30;
         sl.y = 408;
         box.addChild(sl);
         box.addChild(place(RUI.button("导出存档", function():void { saves("aolaSaveExport"); }, 90, 24, 0x6CC0F5, 0x2E86D6, "toolboxExport"), 118, 405));
         box.addChild(place(RUI.button("导入存档", function():void { saves("aolaSaveImport"); }, 90, 24, 0x6CC0F5, 0x2E86D6, "toolboxImport"), 216, 405));

         said = RUI.text(12, 0x8A3B00, true, W - 40);
         said.height = 40;
         said.x = 20;
         said.y = 440;
         box.addChild(said);

         SocketClient.instance.addEventListener("revival_toolbox", onReply);
         SocketClient.instance.addEventListener("2201", onNewPet);
         send({});
         showName();
      }

      private function row(label:String, key:String, value:String, y:int, tip:String = null):void
      {
         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = label;
         t.x = 30;
         t.y = y + 2;
         box.addChild(t);
         var input:TextField = RUI.input(100, value, "0-9", 7, "toolbox_" + key);
         input.x = 118;
         input.y = y;
         box.addChild(input);
         box.addChild(place(RUI.button("增加", function():void
         {
            var o:Object = {};
            o[key] = int(input.text);
            if (o[key] > 0) send(o);
         }, 64, 26, 0xFFC45A, 0xF07812, "toolboxAdd_" + key), 232, y - 2));
         if (tip)
         {
            var tt:TextField = RUI.text(12, 0x557799, false);
            tt.text = tip;
            tt.x = 304;
            tt.y = y + 4;
            box.addChild(tt);
         }
      }

      private static function place(d:DisplayObject, x:Number, y:Number):DisplayObject
      {
         d.x = x;
         d.y = y;
         return d;
      }

      private function showName(e:Event = null):void
      {
         var n:String = "";
         try
         {
            var svc:IPetDictionaryDataService = ServiceContainer.getService(IPetDictionaryDataService) as IPetDictionaryDataService;
            var it:PetDictionaryDataItem = svc ? svc.getDataItemByRaceId(int(raceIn.text)) : null;
            if (it != null) n = it.petName;
         }
         catch (err:Error) {}
         petName.text = int(raceIn.text) <= 0 ? "输入亚比的编号（图鉴里的号码）" : n ? "No." + int(raceIn.text) + "  " + n : "No." + int(raceIn.text) + "  图鉴里没有这只亚比，仍可试试领取";
      }

      /** A place of config.xml by its name or its Chinese name (desc). */
      private static function sceneFor(q:String):String
      {
         var cfg:ConfigReader = ConfigReader.instance;
         if (cfg.getSceneSwf(q)) return q;
         try
         {
            for each (var r:XML in cfg.xmlDocument..r)
            {
               if (String(r.@desc) == q && String(r.@nm) && cfg.getSceneSwf(String(r.@nm))) return String(r.@nm);
            }
            for each (var r2:XML in cfg.xmlDocument..r)
            {
               if (String(r2.@desc).indexOf(q) >= 0 && String(r2.@nm) && cfg.getSceneSwf(String(r2.@nm))) return String(r2.@nm);
            }
         }
         catch (e:Error) { RLog.error("toolbox scene", e); }
         return null;
      }

      private function teleport():void
      {
         var q:String = sceneIn.text.replace(/^\s+|\s+$/g, "");
         if (!q) return;
         var name:String = sceneFor(q);
         if (name == null)
         {
            said.text = "找不到地图「" + q + "」";
            return;
         }
         close();
         SceneManager.getInstance().loadScene(name);
      }

      /** The page's 存档 panel (web/saves.js): export to a file, import from one. */
      private function saves(fn:String):void
      {
         try
         {
            if (ExternalInterface.available)
            {
               ExternalInterface.call(fn);
               close();
               return;
            }
         }
         catch (e:Error) { RLog.error("toolbox saves", e); }
         said.text = "这个页面不能导出导入存档";
      }

      private function getPet():void
      {
         if (int(raceIn.text) <= 0) return;
         send({raceId: int(raceIn.text), level: Math.max(1, Math.min(100, int(levelIn.text)))});
      }

      private function send(o:Object):void
      {
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_toolbox", o);
      }

      private function onReply(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         UserInfo.xingbi = int(p.xingbi);
         totals.text = "晶币 " + int(p.score) + "   星币 " + int(p.xingbi) + "   晶豆 " + int(p.jingdou) + (p.vip == true ? "   蓝宝石" : "");
         if (vip != (p.vip == true))
         {
            vip = p.vip == true;
            var at:int = box.getChildIndex(vipButton);
            box.removeChild(vipButton);
            vipButton = RUI.button(vip ? "取消蓝宝石" : "成为蓝宝石", function():void { send({vip: !vip}); }, 104, 24, 0x6CC0F5, 0x2E86D6, "toolboxVip");
            vipButton.x = W - 128;
            vipButton.y = 58;
            box.addChildAt(vipButton, at);
         }
         if (p.msg) said.text = String(p.msg);
      }

      private function onNewPet(e:SocketClientEvent):void
      {
         // The bag (PetDataService) adds it from the same reply; nothing more to do here.
         RLog.log("toolbox: a new 亚比 in the bag");
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("revival_toolbox", onReply);
         SocketClient.instance.removeEventListener("2201", onNewPet);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
