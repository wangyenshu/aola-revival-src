package mmo.user.login
{
   import flash.display.GradientType;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.ui.Keyboard;
   import mmo.revival.RUI;

   /**
    * REVIVAL. 选择奥拉: 单机模式's own 奥拉, up to three a browser, one a name: 进入, 新建, 改名,
    * 导出, 删除, and 导入 (a 存档 file of either mode: a file of several asks which; a name this
    * page already has asks whether to replace that 奥拉 or to take the file's under another name).
    * The game in the page does the work (web/start.js: game.ts listUsers, createUser, deleteUser,
    * addUserFromFile, rename, exportSave), so its rules hold whatever the screen shows.
    * done(name) once one is chosen; back() on 返回 (to 单机模式 or 联机模式 again: 单机模式's game
    * starts only on 进入, so 返回 leaves the page as it was).
    */
   public class RolesScreen extends Sprite
   {
      private static const MAX:int = 3;
      private static const CW:int = 250;
      private static const CH:int = 312;
      private static const GAP:int = 22;

      private var done:Function;
      private var back:Function;
      private var roles:Array = [];
      private var last:String = "";
      /** The card being worked on: {i, kind: "new" | "rename" | "delete"} (one at a time). */
      private var editing:Object;
      private var cards:Sprite;
      private var bar:Sprite;
      private var msg:TextField;
      private var sheetLayer:Sprite;
      /** What Enter does now (the card or sheet being written in). */
      private var onEnter:Function;
      private var onEsc:Function;
      private var focusField:TextField;

      public function RolesScreen(done:Function, back:Function = null)
      {
         super();
         this.done = done;
         this.back = back;
         addChild(StartPage.backdrop());
         if (back != null)
         {
            var ret:Sprite = RUI.button("返回", function():void { if (sheetLayer.numChildren == 0) back(); }, 80, 30, 0x8FE3FF, 0x1E8FE0, "rolesBack");
            ret.x = 28;
            ret.y = 30;
            addChild(ret);
         }
         var t:TextField = StartPage.title("选择奥拉", 30);
         t.x = (960 - t.width) / 2;
         t.y = 26;
         addChild(t);
         cards = new Sprite();
         cards.y = 92;
         addChild(cards);
         msg = StartPage.centred(14, 0xFFFFFF, false, 900);
         msg.filters = [new DropShadowFilter(1, 90, 0x072A5E, 1, 2, 2, 2)];
         msg.name = "rolesMsg";
         msg.x = 30;
         msg.y = 452;
         msg.height = 24;
         addChild(msg);
         bar = new Sprite();
         bar.y = 488;
         addChild(bar);
         sheetLayer = new Sprite();
         addChild(sheetLayer);
         addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):void
         {
            e.stopPropagation();
            if (e.keyCode == Keyboard.ENTER && onEnter != null) onEnter();
            else if (e.keyCode == Keyboard.ESCAPE && onEsc != null) onEsc();
         });
         refresh(true);
      }

      private function say(text:String, bad:Boolean = false):void
      {
         msg.textColor = bad ? 0xFFD0C4 : 0xFFFFFF;
         msg.text = text || "";
      }

      private function refresh(firstTime:Boolean = false):void
      {
         StartPage.ask("users", {}, function(r:Object):void
         {
            if (r.error) { roles = []; say("读不了这个浏览器里的存档：" + r.error, true); }
            else { roles = r.list as Array || []; last = String(r.last || ""); }
            if (firstTime && roles.length == 0) editing = { i: 0, kind: "new" };
            draw();
         });
      }

      private function draw():void
      {
         while (cards.numChildren > 0) cards.removeChildAt(0);
         onEnter = onEsc = null;
         focusField = null;
         var slots:int = Math.max(MAX, roles.length);
         var w:int = slots * CW + (slots - 1) * GAP;
         for (var i:int = 0; i < slots; i++)
         {
            var c:Sprite = i < roles.length ? roleCard(roles[i], i) : emptyCard(i);
            c.x = (960 - w) / 2 + i * (CW + GAP);
            cards.addChild(c);
         }
         while (bar.numChildren > 0) bar.removeChildAt(0);
         var btns:Array = [RUI.button("导入奥拉", importFlow, 110, 30, 0x8FE3FF, 0x1E8FE0, "rolesImport")];
         if (roles.length) btns.push(RUI.button("全部导出", exportAll, 110, 30, 0x8FE3FF, 0x1E8FE0, "rolesExportAll"));
         var x:int = (960 - (btns.length * 110 + (btns.length - 1) * 12)) / 2;
         for each (var b:Sprite in btns) { b.x = x; bar.addChild(b); x += 122; }
         if (focusField != null && stage != null) stage.focus = focusField;
      }

      // ---------------------------------------------------------------- the cards

      private function card(empty:Boolean, lastOne:Boolean, name:String):Sprite
      {
         var c:Sprite = new Sprite();
         c.name = name;
         var m:Matrix = new Matrix();
         m.createGradientBox(CW, CH, Math.PI / 2);
         c.graphics.lineStyle(3, empty ? 0xCFE9FB : (lastOne ? 0xF6A623 : 0x8CC8EF));
         if (empty) c.graphics.beginFill(0xE8F6FF, 0.55);
         else c.graphics.beginGradientFill(GradientType.LINEAR, [0xF4FBFF, 0xC8E7FA], [1, 1], [0, 255], m);
         c.graphics.drawRoundRect(0, 0, CW, CH, 40, 40);
         c.graphics.endFill();
         if (!empty) c.filters = [new DropShadowFilter(4, 90, 0, 0.35, 12, 12)];
         return c;
      }

      private function face(c:Sprite, letter:String, empty:Boolean):void
      {
         var f:Shape = new Shape();
         var m:Matrix = new Matrix();
         m.createGradientBox(84, 84, 0, CW / 2 - 52, 2);
         f.graphics.lineStyle(3, 0xFFFFFF);
         if (empty) f.graphics.beginFill(0xFFFFFF, 0.6);
         else f.graphics.beginGradientFill(GradientType.RADIAL, [0x8FD8FF, 0x2E86D6], [1, 1], [0, 255], m);
         f.graphics.drawCircle(CW / 2, 64, 42);
         f.graphics.endFill();
         c.addChild(f);
         var t:TextField = StartPage.centred(40, empty ? 0x8CC8EF : 0xFFFFFF, true, CW);
         t.text = letter;
         t.y = 38;
         t.height = 56;
         c.addChild(t);
      }

      private function line(c:Sprite, text:String, y:int, size:int = 13, color:uint = 0x335577, bold:Boolean = false, wrap:int = 216):TextField
      {
         var t:TextField = StartPage.centred(size, color, bold, wrap);
         t.text = text;
         t.x = (CW - wrap) / 2;
         t.y = y;
         t.height = size + 10;
         c.addChild(t);
         return t;
      }

      private function buttonsAt(c:Sprite, y:int, list:Array):void
      {
         var x:int = (CW - (list.length * 90 + (list.length - 1) * 10)) / 2;
         for each (var b:Array in list)
         {
            var s:Sprite = RUI.button(b[0], b[1], 90, 28, b[2] ? b[2] : 0xFFD56A, b[3] ? b[3] : 0xF0840E, b[4]);
            s.x = x;
            s.y = y;
            c.addChild(s);
            x += 100;
         }
      }

      private function input(c:Sprite, value:String, y:int, name:String):TextField
      {
         var t:TextField = RUI.input(196, value, null, 12, name);
         t.x = (CW - 196) / 2;
         t.y = y;
         c.addChild(t);
         focusField = t;
         return t;
      }

      private function roleCard(r:Object, i:int):Sprite
      {
         var name:String = String(r.name);
         var isLast:Boolean = name == last;
         var c:Sprite = card(false, isLast, "role" + i);
         if (isLast)
         {
            var badge:Sprite = new Sprite();
            var bt:TextField = RUI.text(12, 0xFFFFFF, false);
            bt.text = "上次玩的";
            bt.x = 12;
            bt.y = 1;
            badge.graphics.beginFill(0xF39A1E);
            badge.graphics.drawRoundRect(0, 0, bt.width + 24, 20, 20, 20);
            badge.graphics.endFill();
            badge.addChild(bt);
            badge.x = (CW - badge.width) / 2;
            badge.y = -12;
            c.addChild(badge);
         }
         face(c, name.charAt(0) || "奥", false);
         var kind:String = editing && editing.i == i ? editing.kind : "";
         if (kind == "rename")
         {
            var f:TextField = input(c, name, 124, "rolesName");
            var go:Function = function():void
            {
               var to:String = trim(f.text);
               if (to == name) { cancel(); return; }
               StartPage.ask("renameRole", { from: name, to: to }, function(rr:Object):void
               {
                  if (rr.error) { say(rr.error, true); return; }
                  editing = null;
                  say("");
                  refresh();
               });
            };
            buttonsAt(c, 238, [["确定", go, 0, 0, "rolesOk"], ["取消", cancel, 0x8FE3FF, 0x1E8FE0, "rolesCancel"]]);
            onEnter = go;
            onEsc = cancel;
            return c;
         }
         if (kind == "delete")
         {
            line(c, name, 116, 19, 0x1A5FA8, true);
            line(c, "删除" + name + "？删除后不能找回。", 150, 13, 0xB3361C, false).height = 40;
            var ex:Sprite = StartPage.link("先导出一份", function():void { exportOne(name); }, 0x2A628F, "rolesExportFirst");
            ex.x = (CW - ex.width) / 2;
            ex.y = 196;
            c.addChild(ex);
            buttonsAt(c, 238, [["删除", function():void
            {
               StartPage.ask("delete", { name: name }, function(rr:Object):void
               {
                  if (rr.error) { say(rr.error, true); return; }
                  editing = null;
                  say("");
                  refresh();
               });
            }, 0xFF9A80, 0xD9452B, "rolesDelete"], ["取消", cancel, 0x8FE3FF, 0x1E8FE0, "rolesCancel"]]);
            onEsc = cancel;
            return c;
         }
         line(c, name, 116, 19, 0x1A5FA8, true);
         var facts:Array = ["晶币 " + int(r.score), int(r.pets) ? "亚比 " + int(r.pets) + " 只" + (int(r.level) ? "（第一只 Lv" + int(r.level) + "）" : "") : "还没有亚比"];
         if (r.createdAt) facts.push(String(r.createdAt).substr(0, 10) + " 出发");
         for (var k:int = 0; k < facts.length; k++) line(c, facts[k], 148 + k * 20);
         var enter:Sprite = RUI.button("进入", function():void { choose(name); }, 180, 34, 0xFFD56A, 0xF0840E, "rolesEnter" + i);
         enter.x = (CW - 180) / 2;
         enter.y = 232;
         c.addChild(enter);
         var links:Array = [
            StartPage.link("改名", function():void { edit(i, "rename"); }, 0x2A628F, "rolesRename" + i),
            StartPage.link("导出", function():void { exportOne(name); }, 0x2A628F, "rolesExport" + i),
            StartPage.link("删除", function():void { edit(i, "delete"); }, 0xB3361C, "rolesDel" + i)];
         var lx:int = (CW - 3 * 34 - 2 * 14) / 2;
         for each (var l:Sprite in links) { l.x = lx; l.y = 278; c.addChild(l); lx += 48; }
         return c;
      }

      private function emptyCard(i:int):Sprite
      {
         var c:Sprite = card(true, false, "empty" + i);
         face(c, "+", true);
         if (editing && editing.i == i && editing.kind == "new")
         {
            var f:TextField = input(c, "", 124, "rolesName");
            line(c, "奥拉的名字", 150, 12, 0x5A7FA3);
            var go:Function = function():void
            {
               StartPage.ask("create", { name: trim(f.text) }, function(r:Object):void
               {
                  if (r.error) { say(r.error, true); return; }
                  editing = null;
                  say("");
                  refresh();
               });
            };
            var list:Array = [["确定", go, 0, 0, "rolesOk"]];
            if (roles.length) list.push(["取消", cancel, 0x8FE3FF, 0x1E8FE0, "rolesCancel"]);
            buttonsAt(c, 238, list);
            onEnter = go;
            if (roles.length) onEsc = cancel;
            return c;
         }
         line(c, "空位", 116, 19, 0x7FA8C8, true);
         var b:Sprite = RUI.button("新建奥拉", function():void { edit(i, "new"); }, 180, 34, 0x8FE3FF, 0x1E8FE0, "rolesNew" + i);
         b.x = (CW - 180) / 2;
         b.y = 232;
         c.addChild(b);
         return c;
      }

      private function edit(i:int, kind:String):void
      {
         editing = { i: i, kind: kind };
         say("");
         draw();
      }

      private function cancel():void
      {
         editing = null;
         say("");
         draw();
      }

      private function choose(name:String):void
      {
         StartPage.ask("chosen", { name: name }, function(r:Object):void
         {
            // 单机模式's game starts here (one tab of it at a time): a refusal is said on the screen.
            if (r && r.error) { say(String(r.error), true); return; }
            visible = false;
            done(name);
         });
      }

      /** Back after a login the game refused. */
      public function again(why:String):void
      {
         visible = true;
         say(why, true);
         refresh();
      }

      // ---------------------------------------------------------------- files

      private function exportOne(name:String):void
      {
         say("正在准备……");
         StartPage.ask("export", { name: name }, offerFile);
      }

      private function exportAll():void
      {
         say("正在准备……");
         StartPage.ask("exportAll", {}, offerFile);
      }

      /** A file ready: saved from a click (the browser's rule). */
      private function offerFile(r:Object):void
      {
         if (r.error || !r.text) { say(r.error || "没有导出。", true); return; }
         say("");
         sheet("导出存档", "存档准备好了。", function(c:Sprite, close:Function):int
         {
            buttonsAt(c, 96, [["保存文件", function():void
            {
               close();
               StartPage.save(String(r.text), String(r.file), function(m:String):void { say(m); });
            }, 0, 0, "rolesSave"], ["取消", close, 0x8FE3FF, 0x1E8FE0, "rolesSheetCancel"]]);
            return 140;
         });
      }

      private function importFlow():void
      {
         say("");
         StartPage.read(function(text:String):void { bring(text, null, null, false); }, function(m:String):void { say(m, true); });
      }

      /** One 奥拉 of a file into this page: as itself, or (a name taken) replacing or renamed. */
      private function bring(text:String, from:String, asName:String, replace:Boolean):void
      {
         say("正在导入……");
         StartPage.ask("import", { "text": text, "from": from, "as": asName, "replace": replace }, function(r:Object):void
         {
            say("");
            if (r.roles is Array)
            {
               var names:Array = r.roles as Array;
               sheet("选一个奥拉", "", function(c:Sprite, close:Function):int
               {
                  var list:Array = [];
                  for each (var n:String in names) list.push([n, pick(n, close)]);
                  rowOf(c, 64, list);
                  var no:Sprite = StartPage.link("取消", close, 0x2A628F, "rolesSheetCancel");
                  no.x = (360 - no.width) / 2;
                  no.y = 104;
                  c.addChild(no);
                  return 136;
               });
               return;
            }
            if (r.name) { say("已导入。"); refresh(); return; }
            if (r.conflict) { conflict(text, String(r.from), String(r.conflict)); return; }
            say(r.error || "没有导入。", true);
         });
         function pick(n:String, close:Function):Function { return function():void { close(); bring(text, n, null, false); }; }
      }

      private function conflict(text:String, from:String, taken:String):void
      {
         sheet("名字重了", "已经有一个叫" + taken + "的奥拉了。", function(c:Sprite, close:Function):int
         {
            var f:TextField = RUI.input(196, "", null, 12, "rolesNewName");
            f.x = (360 - 196) / 2;
            f.y = 86;
            c.addChild(f);
            var note:TextField = StartPage.centred(13, 0xB3361C, false, 320);
            note.x = 20;
            note.y = 196;
            note.height = 22;
            c.addChild(note);
            var rename:Function = function():void
            {
               var to:String = trim(f.text);
               if (!to) { note.text = "请输入新名字。"; return; }
               StartPage.ask("import", { "text": text, "from": from, "as": to }, function(r:Object):void
               {
                  if (r.name) { close(); say("已导入。"); refresh(); return; }
                  note.text = r.conflict ? "也已经有一个叫" + r.conflict + "的奥拉了。" : (r.error || "没有导入。");
               });
            };
            rowOf(c, 122, [["用新名字导入", rename], ["替换" + taken, function():void { close(); bring(text, from, taken, true); }, 0xFF9A80, 0xD9452B]]);
            var no:Sprite = StartPage.link("取消", close, 0x2A628F, "rolesSheetCancel");
            no.x = (360 - no.width) / 2;
            no.y = 166;
            c.addChild(no);
            onEnter = rename;
            focusField = f;
            return 228;
         });
      }

      private function rowOf(c:Sprite, y:int, list:Array):void
      {
         var widths:Array = [];
         var total:int = 0;
         for each (var b:Array in list)
         {
            var w:int = Math.max(90, String(b[0]).length * 15 + 30);
            widths.push(w);
            total += w;
         }
         total += (list.length - 1) * 10;
         var x:int = (360 - total) / 2;
         for (var i:int = 0; i < list.length; i++)
         {
            var s:Sprite = RUI.button(list[i][0], list[i][1], widths[i], 28, list[i][2] ? list[i][2] : 0xFFD56A, list[i][3] ? list[i][3] : 0xF0840E, "rolesSheet" + i);
            s.x = x;
            s.y = y;
            c.addChild(s);
            x += widths[i] + 10;
         }
      }

      /** A sheet over the cards: build(card, close) draws its answers and gives its height. */
      private function sheet(titleText:String, text:String, build:Function):void
      {
         while (sheetLayer.numChildren > 0) sheetLayer.removeChildAt(0);
         var saveEnter:Function = onEnter;
         var saveEsc:Function = onEsc;
         var dim:Sprite = new Sprite();
         dim.graphics.beginFill(0x041634, 0.55);
         dim.graphics.drawRect(0, 0, 960, 560);
         dim.graphics.endFill();
         dim.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { e.stopPropagation(); });
         sheetLayer.addChild(dim);
         var c:Sprite = new Sprite();
         sheetLayer.addChild(c);
         var close:Function = function():void
         {
            while (sheetLayer.numChildren > 0) sheetLayer.removeChildAt(0);
            onEnter = saveEnter;
            onEsc = saveEsc;
         };
         onEnter = null;
         onEsc = close;
         var tt:TextField = StartPage.centred(19, 0x1A5FA8, true, 320);
         tt.text = titleText;
         tt.x = 20;
         tt.y = 18;
         tt.height = 30;
         c.addChild(tt);
         if (text)
         {
            var tx:TextField = StartPage.centred(13, 0x1A4E7C, false, 320);
            tx.text = text;
            tx.x = 20;
            tx.y = 52;
            tx.height = 24;
            c.addChild(tx);
         }
         focusField = null;
         var h:int = build(c, close);
         var m:Matrix = new Matrix();
         m.createGradientBox(360, h, Math.PI / 2);
         c.graphics.lineStyle(3, 0x8CC8EF);
         c.graphics.beginGradientFill(GradientType.LINEAR, [0xF4FBFF, 0xC8E7FA], [1, 1], [0, 255], m);
         c.graphics.drawRoundRect(0, 0, 360, h, 40, 40);
         c.graphics.endFill();
         c.filters = [new DropShadowFilter(4, 90, 0, 0.35, 12, 12)];
         c.x = 300;
         c.y = (560 - h) / 2;
         if (focusField != null && stage != null) stage.focus = focusField;
      }

      private static function trim(s:String):String
      {
         return String(s || "").replace(/^\s+|\s+$/g, "");
      }
   }
}
