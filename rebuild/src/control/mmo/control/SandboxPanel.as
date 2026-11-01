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
    * The revival's 沙盒 (not of 2013; under the 工具箱): a 关卡 the player sets
    * up, up to MAX opponents fought one after another, each any 亚比 by its
    * number at a level up to 999, its stats (体力, 攻击, 防御, 特攻, 特防, 速度)
    * in percent of what it has at that level; the bag's 亚比 may be healed
    * before each fight. A win brings nothing (no experience). The 关卡 is
    * exported to a file and imported from one (FileReference), to keep and
    * to share; the last one set up is remembered (SharedObject). Server:
    * SundriesExtension.revival_sandbox (sandbox.ts); the file format is in
    * docs/SANDBOX.md.
    */
   public class SandboxPanel extends Sprite
   {
      public static const FORMAT:String = "aola-revival-level";
      private static const MAX:int = 10;
      private static const W:int = 600;
      private static const H:int = 500;
      private static const STATS:Array = [["hp", "体力"], ["at", "攻击"], ["de", "防御"], ["sa", "特攻"], ["sd", "特防"], ["sp", "速度"]];
      private static var current:SandboxPanel;

      /** The 关卡 being fought: {lv (its JSON), name, i, n, race}. */
      private static var run:Object;
      private static var watching:Boolean;

      private var box:Sprite;
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
         watch();
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "沙盒", close, "sandboxClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);

         var t:TextField = RUI.text(14, RUI.BLUE, true);
         t.text = "关卡";
         t.x = 26;
         t.y = 58;
         box.addChild(t);
         nameIn = RUI.input(200, "我的关卡", null, 30, "sandboxName");
         nameIn.x = 70;
         nameIn.y = 56;
         box.addChild(nameIn);
         healBox = RUI.button("", toggleHeal, 150, 24, 0x8ED0FA, 0x3C96DC, "sandboxHeal");
         healBox.x = W - 176;
         healBox.y = 55;
         box.addChild(healBox);

         box.addChild(RUI.well(14, 90, W - 28, 326));
         var heads:Array = [["编号", 24], ["亚比", 78], ["等级", 166]];
         for (var s:int = 0; s < STATS.length; s++) heads.push([STATS[s][1] + "%", 214 + s * 54]);
         for each (var h:Array in heads)
         {
            var ht:TextField = RUI.text(12, RUI.BLUE, true);
            ht.text = h[0];
            ht.x = h[1];
            ht.y = 96;
            box.addChild(ht);
         }
         rows = new Sprite();
         rows.x = 0;
         rows.y = 116;
         box.addChild(rows);

         var bx:int = 18;
         for each (var b:Array in [["添加对手", addEnemy, 88, "sandboxAdd"], ["清空", clearAll, 60, "sandboxClear"], ["导出关卡", exportLevel, 88, "sandboxExport"], ["导入关卡", importLevel, 88, "sandboxImport"]])
         {
            box.addChild(place(RUI.button(b[0], b[1], b[2], 26, 0x6CC0F5, 0x2E86D6, b[3]), bx, 424));
            bx += int(b[2]) + 8;
         }
         box.addChild(place(RUI.button("开始挑战", start, 110, 30, 0xFFC45A, 0xF07812, "sandboxStart"), W - 128, 422));
         said = RUI.text(12, 0x8A3B00, true, W - 40);
         said.height = 36;
         said.x = 20;
         said.y = 458;
         box.addChild(said);

         if (!load(remembered())) load({name: "我的关卡", heal: true, enemies: [{race: 1, level: 120}]});
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
            file.addEventListener(Event.SELECT, function(e:Event):void { file.load(); });
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
         remember(lv);
         run = {lv: RJson.encode(lv), name: lv.name, i: 0, n: enemies.length};
         close();
         fight();
      }

      private static function watch():void
      {
         if (watching) return;
         watching = true;
         SocketClient.instance.addEventListener("revival_sandbox", function(e:SocketClientEvent):void
         {
            if (run == null) return;
            if (e.params.res != 1)
            {
               // Not a 关卡 (its reason), or a start refused (msg "": the battle's 2303 said why).
               run = null;
               if (e.params.msg) NewDialog.showMessage(String(e.params.msg));
               return;
            }
            run.race = int(e.params.race);
         });
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.FIGHT_END, onFightEnd);
      }

      private static function fight():void
      {
         if (run == null) return;
         SocketClient.instance.sendXtMessage("SundriesExtension", "revival_sandbox", {lv: run.lv, i: run.i});
      }

      private static function onFightEnd(e:PetFightEvent):void
      {
         if (run == null || (e.raceId != 0 && int(run.race) != 0 && e.raceId != int(run.race))) return;
         var r:Object = run;
         if (!e.isWin)
         {
            run = null;
            NewDialog.showMessage("关卡「" + r.name + "」挑战失败（第" + (r.i + 1) + "个对手，共" + r.n + "个）。");
            return;
         }
         if (r.i + 1 >= r.n)
         {
            run = null;
            NewDialog.showSucceedMessage("恭喜你通过了关卡「" + r.name + "」！");
            return;
         }
         r.i++;
         r.race = 0;
         // The next opponent once the battle screen has gone.
         var t:Timer = new Timer(1500, 1);
         t.addEventListener(TimerEvent.TIMER, function(te:TimerEvent):void { if (run == r) fight(); });
         t.start();
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
