package mmo.pet.petpackage
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REBUILT: choosing which of its learnt skills a 亚比 carries (at most
    * four). The 2013 panel is lost (no surviving module calls these
    * commands); the commands are the 2013 PetClient's: viewAllSkill
    * (PocketMonsterExtension 1231 -> 2231 {id, skills}) and setUsedSkill
    * (1232 {id, sks: "a,b,c,d"} -> 2232 {res}). A 亚比 learns new skills as
    * it levels up (the server's learnset, 2234); they show here. Drawn in
    * the look of the rebuilt panels; opened by 更换技能 on the 技能 page.
    */
   public class SkillPanel extends Sprite
   {
      private static const W:int = 520;
      private static const H:int = 420;
      /** Skills on a page: five rows of two (a 亚比 of a high level knows twenty and more). */
      private static const PER:int = 10;
      private static var current:SkillPanel;

      private var petId:int;
      private var petName:String;
      private var box:Sprite;
      private var list:Sprite;
      private var said:TextField;
      private var skills:Array = [];
      private var chosen:Array = [];
      private var onDone:Function;
      private var page:int = 0;
      private var pageText:TextField;
      /** A skill's description while the mouse is over it (a click chooses it). */
      private var tip:Sprite;
      /** The skill under the mouse (its tip is shown again when the rows are drawn anew), or -1. */
      private var tipId:int = -1;

      public static function show(petId:int, petName:String, onDone:Function):void
      {
         if (current != null) current.close();
         current = new SkillPanel(petId, petName, onDone);
         LayerManager.getBaseTop().addChild(current);
      }

      public function SkillPanel(petId:int, petName:String, onDone:Function)
      {
         super();
         name = "skillPanel";
         this.petId = petId;
         this.petName = petName;
         this.onDone = onDone;
         addChild(RUI.dim(close));
         box = RUI.panel(W, H, "更换技能", close, "skillClose");
         box.x = (960 - W) / 2;
         box.y = (560 - H) / 2 - 10;
         addChild(box);
         var t:TextField = RUI.text(13, RUI.BLUE, true);
         t.text = petName + " 学会的技能";
         t.x = 24;
         t.y = 56;
         box.addChild(t);
         box.addChild(RUI.well(16, 80, W - 32, 236));
         list = new Sprite();
         list.x = 26;
         list.y = 88;
         box.addChild(list);
         pageText = RUI.text(13, RUI.BLUE, true);
         pageText.y = 324;
         box.addChild(pageText);
         var prev:Sprite = RUI.smallButton("◀", function():void { turn(-1); }, 34, 24, "skillPrev");
         prev.x = W / 2 - 80;
         prev.y = 322;
         box.addChild(prev);
         var next:Sprite = RUI.smallButton("▶", function():void { turn(1); }, 34, 24, "skillNext");
         next.x = W / 2 + 46;
         next.y = 322;
         box.addChild(next);
         said = RUI.text(12, 0x8A3B00, true, W - 150);
         said.height = 40;
         said.x = 20;
         said.y = 354;
         box.addChild(said);
         var ok:Sprite = RUI.button("确定", save, 80, 28, 0xFFC45A, 0xF07812, "skillOk");
         ok.x = W - 112;
         ok.y = H - 44;
         box.addChild(ok);
         SocketClient.instance.addEventListener("2231", onList);
         SocketClient.instance.addEventListener("2232", onSaved);
         PetClient.instance.viewAllSkill(petId);
      }

      private function onList(e:SocketClientEvent):void
      {
         if (int(e.params.id) != petId) return;
         skills = (e.params.skills as Array) || [];
         chosen = [];
         for each (var s:Object in skills) if (s.used == true) chosen.push(int(s.id));
         page = 0;
         draw();
      }

      private function draw():void
      {
         removeTip();
         while (list.numChildren) list.removeChildAt(0);
         var pages:int = Math.max(1, Math.ceil(skills.length / PER));
         page = Math.max(0, Math.min(page, pages - 1));
         pageText.text = (page + 1) + " / " + pages;
         pageText.x = W / 2 - pageText.width / 2;
         for (var k:int = 0; k < PER && page * PER + k < skills.length; k++)
         {
            var i:int = k;
            var s:Object = skills[page * PER + k];
            var on:Boolean = chosen.indexOf(int(s.id)) >= 0;
            var row:Sprite = new Sprite();
            row.name = "skill_" + int(s.id);
            row.buttonMode = true;
            row.mouseChildren = false;
            row.x = (i % 2) * 236;
            row.y = int(i / 2) * 44;
            row.graphics.lineStyle(2, on ? 0xF07812 : 0xF2C27A);
            row.graphics.beginFill(on ? 0xFFF1C9 : 0xFFFFFF);
            row.graphics.drawRoundRect(0, 0, 226, 38, 12, 12);
            row.graphics.endFill();
            var n:TextField = RUI.text(13, on ? 0xC25A00 : RUI.BLUE, true);
            n.text = (on ? "✔ " : "") + s.name;
            n.x = 8;
            n.y = 2;
            row.addChild(n);
            var d:TextField = RUI.text(11, 0x557799, false);
            d.text = (int(s.power) > 0 ? "威力 " + int(s.power) + "   " : int(s.kind) == 2 ? "变化   " : "") + "PP " + s.pp;
            d.x = 8;
            d.y = 20;
            row.addChild(d);
            row.addEventListener(MouseEvent.CLICK, toggle(int(s.id)));
            var over:Function = hover(row, int(s.id), String(s.name), String(s.desc || ""));
            row.addEventListener(MouseEvent.ROLL_OVER, over);
            row.addEventListener(MouseEvent.ROLL_OUT, unhover);
            list.addChild(row);
            // A click draws the rows anew under the mouse: its tip stays.
            if (int(s.id) == tipId) over(null);
         }
         said.text = skills.length ? "已选 " + chosen.length + " / 4    （把鼠标放在技能上看说明，点一下选上或取下）" : "正在读取技能……";
      }

      private function turn(by:int):void
      {
         page += by;
         draw();
      }

      /** Its description beside the skill under the mouse. */
      private function hover(row:Sprite, id:int, title:String, desc:String):Function
      {
         return function(e:MouseEvent):void
         {
            removeTip();
            tipId = id;
            tip = new Sprite();
            tip.name = "skillTip";
            tip.mouseEnabled = tip.mouseChildren = false;
            var t1:TextField = RUI.text(12, 0xFFFFFF, true);
            t1.text = title;
            t1.x = 8;
            t1.y = 5;
            var t2:TextField = RUI.text(12, 0xFFE66A, false, 184);
            t2.text = desc || "这个技能没有说明。";
            t2.autoSize = TextFieldAutoSize.LEFT;
            t2.x = 8;
            t2.y = 24;
            tip.graphics.lineStyle(1, 0x6FB6E8);
            tip.graphics.beginFill(0x123A7A, 0.92);
            tip.graphics.drawRoundRect(0, 0, 200, t2.y + t2.height + 8, 8, 8);
            tip.graphics.endFill();
            tip.addChild(t1);
            tip.addChild(t2);
            // Beside the row, inside the panel: right of a left-hand skill, left of a right-hand one.
            tip.x = list.x + row.x + (row.x > 0 ? -206 : 232);
            tip.y = Math.min(list.y + row.y, H - tip.height - 8);
            box.addChild(tip);
         };
      }

      private function unhover(e:MouseEvent = null):void
      {
         tipId = -1;
         removeTip();
      }

      private function removeTip():void
      {
         if (tip && tip.parent) tip.parent.removeChild(tip);
         tip = null;
      }

      private function toggle(id:int):Function
      {
         return function(e:MouseEvent):void
         {
            e.stopPropagation();
            var i:int = chosen.indexOf(id);
            if (i >= 0)
            {
               if (chosen.length <= 1) { said.text = "至少要带一个技能哦！"; return; }
               chosen.splice(i, 1);
            }
            else
            {
               if (chosen.length >= 4) { said.text = "最多只能带四个技能，先取下一个吧。"; return; }
               chosen.push(id);
            }
            draw();
         };
      }

      private function save():void
      {
         if (chosen.length == 0) return;
         // Keep the order the skills were learnt in.
         var ids:Array = [];
         for each (var s:Object in skills) if (chosen.indexOf(int(s.id)) >= 0) ids.push(int(s.id));
         PetClient.instance.setUsedSkill(petId, ids.join(","));
      }

      private function onSaved(e:SocketClientEvent):void
      {
         if (int(e.params.id) != petId) return;
         if (int(e.params.res) != 1)
         {
            said.text = "没有换成，请再试一次。";
            return;
         }
         try { PetClient.instance.viewAllPM(); } catch (err:Error) { RLog.error("skills refresh", err); }
         if (onDone != null) onDone();
         close();
      }

      public function close():void
      {
         SocketClient.instance.removeEventListener("2231", onList);
         SocketClient.instance.removeEventListener("2232", onSaved);
         if (parent) parent.removeChild(this);
         if (current == this) current = null;
      }
   }
}
