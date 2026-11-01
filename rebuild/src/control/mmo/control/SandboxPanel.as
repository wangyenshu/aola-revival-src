package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.TimerEvent;
   import flash.net.FileFilter;
   import flash.net.FileReference;
   import flash.net.SharedObject;
   import flash.net.URLLoader;
   import flash.net.URLLoaderDataFormat;
   import flash.text.TextField;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDictionaryDataService;
   import mmo.interfaces.pet.data.PetDictionaryDataItem;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.loader.scheduler.VersManager;
   import mmo.revival.RJson;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * The revival's 沙盒 (not of 2013; under the 工具箱), two pages:
    *
    * 对手关卡: a 关卡 the player sets up, up to MAX opponents fought one after
    * another, each any 亚比 by its number at a level up to 999, its stats
    * (体力, 攻击, 防御, 特攻, 特防, 速度) in percent of what it has at that level;
    * the bag's 亚比 may be healed before each fight. Exported to a file and
    * imported from one (FileReference); the last one is remembered
    * (SharedObject).
    *
    * 模组: mods, SWFs written in ActionScript 3 against the mod API
    * (mmo.revival.mod; docs/MODDING.md): imported from a file or picked from
    * the examples the site has (revival/mods/index.json), then started
    * (ModRun): their rooms, characters, films and 亚比.
    *
    * A win of the 对手关卡 brings nothing (no experience). Server:
    * SundriesExtension.revival_sandbox (sandbox.ts); its file format is in
    * docs/MODDING.md.
    */
   public class SandboxPanel extends Sprite
   {
      public static const FORMAT:String = "aola-revival-level";
      private static const MAX:int = 10;
      private static const W:int = 600;
      private static const H:int = 528;
      private static const STATS:Array = [["hp", "体力"], ["at", "攻击"], ["de", "防御"], ["sa", "特攻"], ["sd", "特防"], ["sp", "速度"]];
      private static var current:SandboxPanel;

      /** The examples of the site (revival/mods/index.json), once read. */
      private static var examples:Array;
      private static var lastPage:String = "fights";

      private var box:Sprite;
      private var fightsPage:Sprite;
      private var modsPage:Sprite;
      private var loadedRows:Sprite;
      private var exampleRows:Sprite;
      /** Example file -> the id of the mod it loaded. */
      private static var exampleIds:Object = {};
      private var nameIn:TextField;
      private var healBox:Sprite;
      private var heal:Boolean = true;
      private var rows:Sprite;
      private var said:TextField;
      private var enemies:Array = [];
      private var file:FileReference;

      public static function toggle():void
      {
         if (current != null && current.parent != null)
         {
            current.close();
            return;
         }
         current = new SandboxPanel();
         LayerManager.getBaseTop().addChild(current);
      }

      public function SandboxPanel()
      {
         super();
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "沙盒", close, "sandboxClose");
         box.x = (960 - W) / 2;
         box.y = Math.max(2, (560 - H) / 2 - 8);
         addChild(box);
         box.addChild(place(RUI.button("对手关卡", function():void { showPage("fights"); }, 100, 24, 0x8ED0FA, 0x3C96DC, "sandboxTabFights"), 18, 48));
         box.addChild(place(RUI.button("模组", function():void { showPage("mods"); }, 100, 24, 0x8ED0FA, 0x3C96DC, "sandboxTabMods"), 124, 48));
         fightsPage = new Sprite();
         fightsPage.y = 26;
         box.addChild(fightsPage);
         modsPage = new Sprite();
         modsPage.y = 26;
         box.addChild(modsPage);

         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = "关卡";
         t.x = 26;
         t.y = 58;
         fightsPage.addChild(t);
         nameIn = RUI.input(200, "我的关卡", null, 30, "sandboxName");
         nameIn.x = 70;
         nameIn.y = 56;
         fightsPage.addChild(nameIn);
         healBox = RUI.button("", toggleHeal, 150, 24, 0x8ED0FA, 0x3C96DC, "sandboxHeal");
         healBox.x = W - 176;
         healBox.y = 55;
         fightsPage.addChild(healBox);

         fightsPage.addChild(RUI.well(14, 90, W - 28, 326));
         var heads:Array = [["编号", 24], ["亚比", 78], ["等级", 166]];
         for (var s:int = 0; s < STATS.length; s++) heads.push([STATS[s][1] + "%", 214 + s * 54]);
         for each (var h:Array in heads)
         {
            var ht:TextField = RUI.text(12, RUI.BLUE, true);
            ht.text = h[0];
            ht.x = h[1];
            ht.y = 96;
            fightsPage.addChild(ht);
         }
         rows = new Sprite();
         rows.x = 0;
         rows.y = 116;
         fightsPage.addChild(rows);

         var bx:int = 18;
         for each (var b:Array in [["添加对手", addEnemy, 88, "sandboxAdd"], ["清空", clearAll, 60, "sandboxClear"], ["导出关卡", exportLevel, 88, "sandboxExport"], ["导入关卡", importLevel, 88, "sandboxImport"]])
         {
            fightsPage.addChild(place(RUI.button(b[0], b[1], b[2], 26, 0x6CC0F5, 0x2E86D6, b[3]), bx, 424));
            bx += int(b[2]) + 8;
         }
         fightsPage.addChild(place(RUI.button("开始挑战", start, 110, 30, 0xFFC45A, 0xF07812, "sandboxStart"), W - 128, 422));
         said = RUI.text(12, 0x8A3B00, true, W - 40);
         said.height = 36;
         said.x = 20;
         said.y = 486;
         box.addChild(said);

         buildModsPage();
         if (!load(remembered())) load({name: "我的关卡", heal: true, enemies: [{race: 1, level: 120}]});
         showPage(lastPage);
      }

      private function showPage(which:String):void
      {
         lastPage = which;
         fightsPage.visible = which == "fights";
         modsPage.visible = which == "mods";
         if (which == "mods") drawMods();
      }

      // ---------------------------------------------------------------- 模组 (mods)

      private function buildModsPage():void
      {
         var have:TextField = RUI.text(13, RUI.BLUE, true);
         have.text = "已载入的模组";
         have.x = 26;
         have.y = 50;
         modsPage.addChild(have);
         modsPage.addChild(RUI.well(14, 70, W - 28, 120));
         loadedRows = new Sprite();
         loadedRows.y = 76;
         modsPage.addChild(loadedRows);
         var hint:TextField = RUI.text(11, 0x557799, false, W - 50);
         hint.wordWrap = true;
         hint.width = W - 50;
         hint.text = "模组是用 ActionScript 3 写的 SWF 文件（说明见 docs/MODDING.md），里面的程序在游戏里运行：只导入你信任的模组。可以同时载入几个不冲突的模组。";
         hint.x = 26;
         hint.y = 194;
         modsPage.addChild(hint);
         var ex:TextField = RUI.text(13, RUI.BLUE, true);
         ex.text = "示例模组";
         ex.x = 26;
         ex.y = 224;
         modsPage.addChild(ex);
         modsPage.addChild(RUI.well(14, 244, W - 28, 168));
         exampleRows = new Sprite();
         exampleRows.y = 250;
         modsPage.addChild(exampleRows);
         modsPage.addChild(place(RUI.button("导入模组", importMod, 110, 26, 0x6CC0F5, 0x2E86D6, "sandboxImportMod"), 18, 424));
      }

      private function drawMods():void
      {
         // The mods loaded: each with 开始 and 移除.
         while (loadedRows.numChildren > 0) loadedRows.removeChildAt(0);
         var list:Array = ModRun.instance.mods;
         if (list.length == 0)
         {
            var none:TextField = RUI.text(13, 0x557799, false, W - 70);
            none.text = "还没有载入模组：导入一个模组文件（.swf），或载入下面的示例。";
            none.x = 30;
            none.y = 6;
            loadedRows.addChild(none);
         }
         for (var k:int = 0; k < list.length && k < 4; k++)
         {
            var m:Object = list[k];
            var mt:TextField = RUI.text(13, 0x335577, true, W - 230);
            mt.wordWrap = true;
            mt.width = W - 230;
            mt.text = String(m.name) + (m.version ? " " + m.version : "") + (m.author ? "  作者：" + m.author : "");
            mt.x = 30;
            mt.y = k * 28 + 3;
            loadedRows.addChild(mt);
            loadedRows.addChild(place(RUI.button("开始", startModOf(m.id), 64, 26, 0xFFC45A, 0xF07812, "sandboxStart_" + k), W - 180, k * 28));
            loadedRows.addChild(place(RUI.button("移除", removeModOf(m.id), 64, 26, 0xF5A08C, 0xD9452B, "sandboxRemove_" + k), W - 108, k * 28));
         }
         // The site's examples: each with 载入, and 移除 once loaded.
         while (exampleRows.numChildren > 0) exampleRows.removeChildAt(0);
         if (examples == null)
         {
            readExamples();
            return;
         }
         for (var i:int = 0; i < examples.length && i < 4; i++)
         {
            var e:Object = examples[i];
            var t:TextField = RUI.text(13, 0x335577, true, W - 230);
            t.wordWrap = true;
            t.width = W - 230;
            t.text = String(e.name || e.file) + (e.description ? "：" + String(e.description) : "");
            t.x = 30;
            t.y = i * 40 + 2;
            exampleRows.addChild(t);
            exampleRows.addChild(place(RUI.button("载入", loadExample(e), 64, 26, 0x8ED0FA, 0x3C96DC, "sandboxExample_" + i), W - 180, i * 40));
            var id:String = exampleIds[String(e.file)];
            var on:Boolean = id != null && isLoaded(id);
            var rm:Sprite = RUI.button("移除", on ? removeModOf(id) : null, 64, 26, 0xF5A08C, 0xD9452B, "sandboxExampleRemove_" + i);
            rm.alpha = on ? 1 : 0.4;
            exampleRows.addChild(place(rm, W - 108, i * 40));
         }
      }

      private static function isLoaded(id:String):Boolean
      {
         for each (var m:Object in ModRun.instance.mods) if (m.id == id) return true;
         return false;
      }

      /** The site's examples: revival/mods/index.json, [{file, name, description}]. */
      private function readExamples():void
      {
         examples = [];
         var ld:URLLoader = new URLLoader();
         ld.addEventListener(Event.COMPLETE, function(e:Event):void
         {
            try { examples = (RJson.decode(String(ld.data)) as Array) || []; } catch (err:Error) { examples = []; }
            if (parent != null) drawMods();
         });
         ld.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { RLog.log("sandbox: no revival/mods/index.json"); });
         try { ld.load(VersManager.getVerURLRequest("revival/mods/index.json")); } catch (err:Error) { RLog.error("sandbox examples", err); }
      }

      private function loadExample(e:Object):Function
      {
         return function():void
         {
            var file:String = String(e.file || "");
            if (!/^[A-Za-z0-9_-]+\.swf$/.test(file)) return;
            said.text = "正在载入示例模组……";
            var ld:URLLoader = new URLLoader();
            ld.dataFormat = URLLoaderDataFormat.BINARY;
            ld.addEventListener(Event.COMPLETE, function(ev:Event):void { gotMod(ld.data as ByteArray, file); });
            ld.addEventListener(IOErrorEvent.IO_ERROR, function(ev:Event):void { said.text = "示例模组读取失败。"; });
            try { ld.load(VersManager.getVerURLRequest("revival/mods/" + file)); } catch (err:Error) { said.text = "示例模组读取失败。"; }
         };
      }

      private function importMod():void
      {
         try
         {
            file = new FileReference();
            file.addEventListener(Event.SELECT, function(e:Event):void
            {
               var big:Boolean = false;
               try { big = file.size > ModRun.MAX_BYTES; } catch (se:Error) {}
               if (big) said.text = "文件太大了（模组最多16 MB）。";
               else file.load();
            });
            file.addEventListener(Event.COMPLETE, function(e:Event):void { gotMod(file.data); });
            file.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { said.text = "读取失败。"; });
            file.browse([new FileFilter("模组 (*.swf)", "*.swf")]);
         }
         catch (err:Error)
         {
            RLog.error("sandbox import mod", err);
            said.text = "这个页面不能选择文件。";
         }
      }

      /** A mod's bytes read (a file, or the example of that file): loaded beside the others. */
      public function gotMod(bytes:ByteArray, example:String = null):void
      {
         ModRun.instance.load(bytes, function(err:String, m:Object):void
         {
            if (err == null && example != null) exampleIds[example] = m.id;
            said.text = err != null ? err : "已载入模组「" + m.name + "」：点它的「开始」。";
            if (parent != null) drawMods();
         });
      }

      /** 开始 of a mod loaded. */
      private function startModOf(id:String):Function
      {
         return function():void
         {
            if (!isLoaded(id)) return;
            close();
            ModRun.instance.startMod(id);
         };
      }

      /** 移除 of a mod loaded (leaving its room if the player is in it). */
      private function removeModOf(id:String):Function
      {
         return function():void
         {
            var name:String = id;
            for each (var m:Object in ModRun.instance.mods) if (m.id == id) name = String(m.name);
            if (!isLoaded(id)) return;
            var inside:Boolean = ModRun.instance.currentRoom != null && ModRun.instance.loaded != null && ModRun.instance.loaded.id == id;
            ModRun.instance.unload(id);
            said.text = "已移除模组「" + name + "」。";
            drawMods();
            if (inside) close();
         };
      }

      // ---------------------------------------------------------------- the 关卡 in the panel

      private function load(lv:Object):Boolean
      {
         if (lv == null || !(lv.enemies is Array)) return false;
         enemies = [];
         for each (var e:Object in lv.enemies)
         {
            if (enemies.length >= MAX) break;
            var o:Object = {race: int(e.race), level: Math.max(1, Math.min(999, int(e.level) || 1))};
            for each (var st:Array in STATS) o[st[0]] = e[st[0]] == null ? 100 : Math.max(1, Math.min(10000, int(e[st[0]])));
            enemies.push(o);
         }
         nameIn.text = lv.name ? String(lv.name).substr(0, 30) : "我的关卡";
         heal = lv.heal !== false;
         showHeal();
         drawRows();
         return true;
      }

      /** The 关卡 as set up now (the file's object). */
      private function level():Object
      {
         readRows();
         return {format: FORMAT, version: 1, name: nameIn.text, heal: heal, enemies: enemies.concat()};
      }

      private function drawRows():void
      {
         while (rows.numChildren > 0) rows.removeChildAt(0);
         for (var i:int = 0; i < enemies.length; i++)
         {
            var e:Object = enemies[i];
            var y:int = i * 29;
            var race:TextField = RUI.input(46, String(e.race), "0-9", 4, "sandboxRace" + i);
            race.x = 22;
            race.y = y;
            rows.addChild(race);
            var nm:TextField = RUI.text(12, 0x335577, true);
            nm.x = 74;
            nm.y = y + 3;
            nm.text = petName(int(e.race));
            rows.addChild(nm);
            race.addEventListener(Event.CHANGE, nameOf(race, nm));
            var lv:TextField = RUI.input(40, String(e.level), "0-9", 3, "sandboxLevel" + i);
            lv.x = 164;
            lv.y = y;
            rows.addChild(lv);
            for (var s:int = 0; s < STATS.length; s++)
            {
               var st:TextField = RUI.input(46, String(e[STATS[s][0]]), "0-9", 5, "sandbox_" + STATS[s][0] + i);
               st.x = 212 + s * 54;
               st.y = y;
               rows.addChild(st);
            }
            rows.addChild(place(RUI.smallButton("删", removeAt(i), 32, 22, "sandboxDel" + i), 540, y));
         }
         if (enemies.length == 0)
         {
            var none:TextField = RUI.text(13, 0x557799, false);
            none.text = "还没有对手：点「添加对手」";
            none.x = 30;
            none.y = 6;
            rows.addChild(none);
         }
      }

      private function nameOf(race:TextField, nm:TextField):Function
      {
         return function(e:Event):void { nm.text = petName(int(race.text)); };
      }

      private function removeAt(i:int):Function
      {
         return function():void
         {
            readRows();
            enemies.splice(i, 1);
            drawRows();
         };
      }

      /** The rows' text boxes back into enemies. */
      private function readRows():void
      {
         for (var i:int = 0; i < enemies.length; i++)
         {
            var e:Object = enemies[i];
            e.race = int(field("sandboxRace" + i));
            e.level = Math.max(1, Math.min(999, int(field("sandboxLevel" + i)) || 1));
            // An empty box is 100%; anything typed is held to 1%–10000% (0 is 1%, as the server reads it).
            for each (var st:Array in STATS)
            {
               var v:String = field("sandbox_" + st[0] + i);
               e[st[0]] = v == "" ? 100 : Math.max(1, Math.min(10000, int(v)));
            }
         }
      }

      private function field(name:String):String
      {
         var t:TextField = rows.getChildByName(name) as TextField;
         return t ? t.text : "";
      }

      private static function petName(race:int):String
      {
         if (race <= 0) return "—";
         try
         {
            var svc:IPetDictionaryDataService = ServiceContainer.getService(IPetDictionaryDataService) as IPetDictionaryDataService;
            var it:PetDictionaryDataItem = svc ? svc.getDataItemByRaceId(race) : null;
            if (it != null && it.petName) return it.petName;
         }
         catch (err:Error) {}
         return "（图鉴里没有）";
      }

      private function addEnemy():void
      {
         readRows();
         if (enemies.length >= MAX)
         {
            said.text = "一个关卡最多" + MAX + "个对手";
            return;
         }
         var last:Object = enemies.length ? enemies[enemies.length - 1] : null;
         var o:Object = {race: last ? last.race : 1, level: last ? last.level : 120};
         for each (var st:Array in STATS) o[st[0]] = last ? last[st[0]] : 100;
         enemies.push(o);
         drawRows();
      }

      private function clearAll():void
      {
         enemies = [];
         drawRows();
      }

      private function toggleHeal():void
      {
         heal = !heal;
         showHeal();
      }

      private function showHeal():void
      {
         var label:TextField = null;
         for (var i:int = 0; i < healBox.numChildren; i++) if (healBox.getChildAt(i) is TextField) label = healBox.getChildAt(i) as TextField;
         if (label == null) return;
         label.text = heal ? "每场前恢复体力：是" : "每场前恢复体力：否";
         // The button was made with no text: centred again now that it has some.
         label.x = (150 - label.width) / 2;
         label.y = (24 - label.height) / 2;
      }

      // ---------------------------------------------------------------- files

      private function exportLevel():void
      {
         var lv:Object = level();
         remember(lv);
         try
         {
            file = new FileReference();
            file.addEventListener(Event.COMPLETE, function(e:Event):void { said.text = "关卡已保存。"; });
            file.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { said.text = "保存失败。"; });
            file.save(RJson.encode(lv), safeName(nameIn.text) + ".json");
         }
         catch (err:Error)
         {
            RLog.error("sandbox export", err);
            said.text = "这个页面不能保存文件。";
         }
      }

      private function importLevel():void
      {
         try
         {
            file = new FileReference();
            file.addEventListener(Event.SELECT, function(e:Event):void
            {
               var big:Boolean = false;
               try { big = file.size > 1000000; } catch (se:Error) {}
               if (big) said.text = "这不是奥拉星的关卡文件。";
               else file.load();
            });
            file.addEventListener(Event.COMPLETE, function(e:Event):void
            {
               try
               {
                  var data:ByteArray = file.data;
                  data.position = 0;
                  var lv:Object = RJson.decode(data.readUTFBytes(data.length));
                  if (lv == null || (lv.format != null && lv.format != FORMAT) || !(lv.enemies is Array)) throw new Error("not a level");
                  load(lv);
                  remember(level());
                  showPage("fights");
                  said.text = "已导入关卡「" + nameIn.text + "」（" + enemies.length + "个对手）。";
               }
               catch (err:Error)
               {
                  said.text = "这不是奥拉星的关卡文件。";
               }
            });
            file.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void { said.text = "读取失败。"; });
            file.browse([new FileFilter("关卡 (*.json)", "*.json")]);
         }
         catch (err:Error)
         {
            RLog.error("sandbox import", err);
            said.text = "这个页面不能选择文件。";
         }
      }

      /** The file's name: aola-level-<name>.json, its name's letters and digits only (Ruffle's save took no other). */
      private static function safeName(s:String):String
      {
         var n:String = s.replace(/[^A-Za-z0-9_\-]+/g, "");
         return n ? "aola-level-" + n : "aola-level";
      }

      private static function remembered():Object
      {
         try
         {
            var so:SharedObject = SharedObject.getLocal("aolaSandbox", "/");
            return so.data.level ? RJson.decode(String(so.data.level)) : null;
         }
         catch (err:Error) {}
         return null;
      }

      private static function remember(lv:Object):void
      {
         try
         {
            var so:SharedObject = SharedObject.getLocal("aolaSandbox", "/");
            so.data.level = RJson.encode(lv);
            so.flush();
         }
         catch (err:Error) {}
      }

      // ---------------------------------------------------------------- the fights

      private function start():void
      {
         var lv:Object = level();
         if (enemies.length == 0)
         {
            said.text = "先添加对手。";
            return;
         }
         if (SandboxRun.fighting) return;
         remember(lv);
         close();
         var name:String = String(lv.name);
         var n:int = enemies.length;
         SandboxRun.fight(lv, function(win:Boolean, at:int, refused:Boolean = false):void
         {
            if (refused) return;
            if (win) NewDialog.showSucceedMessage("恭喜你通过了关卡「" + name + "」！");
            else NewDialog.showMessage("关卡「" + name + "」挑战失败（第" + (at + 1) + "个对手，共" + n + "个）。");
         });
      }

      private static function place(d:DisplayObject, x:Number, y:Number):DisplayObject
      {
         d.x = x;
         d.y = y;
         return d;
      }

      public function close():void
      {
         if (parent != null) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
