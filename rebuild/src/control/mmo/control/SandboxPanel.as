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
    * 地图关卡: a 关卡 pack (format version 2, made with the editor beside the
    * game): its 关卡 listed, each started in its rooms (SandboxRun, the 沙盒
    * room).
    *
    * A win brings nothing (no experience). Server:
    * SundriesExtension.revival_sandbox (sandbox.ts); the formats are in
    * docs/SANDBOX.md.
    */
   public class SandboxPanel extends Sprite
   {
      public static const FORMAT:String = "aola-revival-level";
      private static const MAX:int = 10;
      private static const W:int = 600;
      private static const H:int = 528;
      private static const LEVELS_A_PAGE:int = 9;
      private static const STATS:Array = [["hp", "体力"], ["at", "攻击"], ["de", "防御"], ["sa", "特攻"], ["sd", "特防"], ["sp", "速度"]];
      private static var current:SandboxPanel;

      /** The 关卡 pack imported (version 2), kept while the game runs. */
      private static var pack:Object;
      private static var lastPage:String = "fights";

      private var box:Sprite;
      private var fightsPage:Sprite;
      private var packPage:Sprite;
      private var packInfo:TextField;
      private var levelRows:Sprite;
      private var levelPage:int;
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
         box.addChild(place(RUI.button("地图关卡", function():void { showPage("pack"); }, 100, 24, 0x8ED0FA, 0x3C96DC, "sandboxTabPack"), 124, 48));
         fightsPage = new Sprite();
         fightsPage.y = 26;
         box.addChild(fightsPage);
         packPage = new Sprite();
         packPage.y = 26;
         box.addChild(packPage);

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

         buildPackPage();
         if (!load(remembered())) load({name: "我的关卡", heal: true, enemies: [{race: 1, level: 120}]});
         showPage(pack != null ? lastPage : "fights");
      }

      private function showPage(which:String):void
      {
         lastPage = which;
         fightsPage.visible = which == "fights";
         packPage.visible = which == "pack";
         if (which == "pack") drawPack();
      }

      // ---------------------------------------------------------------- 地图关卡 (packs)

      private function buildPackPage():void
      {
         packInfo = RUI.text(13, RUI.BLUE, true, W - 60);
         packInfo.height = 22;
         packInfo.x = 26;
         packInfo.y = 56;
         packPage.addChild(packInfo);
         var hint:TextField = RUI.text(11, 0x557799, false, W - 50);
         hint.text = "关卡包用网站上的关卡编辑器（editor/）制作：图片、房间、门和对手都在一个文件里。";
         hint.x = 26;
         hint.y = 76;
         packPage.addChild(hint);
         packPage.addChild(RUI.well(14, 96, W - 28, 310));
         levelRows = new Sprite();
         levelRows.y = 106;
         packPage.addChild(levelRows);
         packPage.addChild(place(RUI.button("导入关卡包", importLevel, 110, 26, 0x6CC0F5, 0x2E86D6, "sandboxImportPack"), 18, 424));
         packPage.addChild(place(RUI.smallButton("上一页", function():void { levelPage--; drawPack(); }, 70, 26, "sandboxLevelsPrev"), W - 168, 424));
         packPage.addChild(place(RUI.smallButton("下一页", function():void { levelPage++; drawPack(); }, 70, 26, "sandboxLevelsNext"), W - 90, 424));
      }

      private function drawPack():void
      {
         while (levelRows.numChildren > 0) levelRows.removeChildAt(0);
         if (pack == null)
         {
            packInfo.text = "还没有关卡包：点「导入关卡包」。";
            return;
         }
         var levels:Array = pack.levels as Array;
         var pages:int = Math.max(1, Math.ceil(levels.length / LEVELS_A_PAGE));
         levelPage = Math.max(0, Math.min(pages - 1, levelPage));
         packInfo.text = "关卡包「" + String(pack.name || "未命名") + "」" + (pack.author ? "  作者：" + String(pack.author).substr(0, 30) : "") + "  共" + levels.length + "关" + (pages > 1 ? "（第" + (levelPage + 1) + "/" + pages + "页）" : "");
         for (var i:int = 0; i < LEVELS_A_PAGE && levelPage * LEVELS_A_PAGE + i < levels.length; i++)
         {
            var n:int = levelPage * LEVELS_A_PAGE + i;
            var l:Object = levels[n];
            var t:TextField = RUI.text(13, 0x335577, true);
            t.text = (n + 1) + ". " + String(l.name || l.id).substr(0, 30) + "    " + (l.rooms is Array ? l.rooms.length : 0) + "个房间";
            t.x = 30;
            t.y = i * 32 + 4;
            levelRows.addChild(t);
            levelRows.addChild(place(RUI.button("开始", startLevel(String(l.id)), 70, 26, 0xFFC45A, 0xF07812, "sandboxLevel_" + n), W - 110, i * 32));
         }
      }

      private function startLevel(id:String):Function
      {
         return function():void
         {
            var why:String = SandboxRun.check(pack);
            if (why != null)
            {
               said.text = why;
               return;
            }
            close();
            SandboxRun.start(pack, id);
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
         label.x = (150 - label.width) / 2;
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
               // A pack is at most 16 MB (docs/SANDBOX.md).
               var big:Boolean = false;
               try { big = file.size > 16000000; } catch (se:Error) {}
               if (big) said.text = "文件太大了（关卡包最多16 MB）。";
               else file.load();
            });
            file.addEventListener(Event.COMPLETE, function(e:Event):void
            {
               try
               {
                  var data:ByteArray = file.data;
                  data.position = 0;
                  var lv:Object = RJson.decode(data.readUTFBytes(data.length));
                  if (lv != null && lv.levels is Array)
                  {
                     // A 关卡 pack (version 2): its 关卡 on the 地图关卡 page.
                     var why:String = SandboxRun.check(lv);
                     if (why != null)
                     {
                        said.text = why;
                        return;
                     }
                     pack = lv;
                     SandboxRun.reset();
                     levelPage = 0;
                     showPage("pack");
                     said.text = "已导入关卡包「" + String(lv.name || "未命名") + "」（" + lv.levels.length + "关）。";
                     return;
                  }
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
