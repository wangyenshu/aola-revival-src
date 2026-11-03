package mmo.pet.petpackage
{
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.utils.getDefinitionByName;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.revival.RLog;
   import mmo.revival.RUI;

   /**
    * REVIVAL 战术卡 (the bag's 战术卡 tab; the 2013 page is lost): the three places of the 亚比
    * chosen (A, B, C: PetCardTypes) and the cards one has. A card clicked goes on in its place
    * (the one there comes back); a card worn, clicked, comes off. The cards are the 2013
    * materialdata PetCardData; the server: MaterialExtension 61_7 (the cards one has) and
    * PetExtension 54_25 {cid, pid} (petcards.ts).
    */
   public class CardPage extends Sprite
   {
      public static const W:int = 360;
      public static const H:int = 250;
      private static const PER_PAGE:int = 8;
      private static const TYPES:Array = ["A", "B", "C"];
      /** 斗士, 武者, 勇者. */
      private static const COLORS:Array = [0x2C7A2C, 0x1A5FA8, 0xB0420F];

      private var petId:Function;
      private var places:Sprite = new Sprite();
      private var list:Sprite = new Sprite();
      private var said:TextField;
      private var pageText:TextField;
      private var mine:Array = [];
      private var worn:Array = [0, 0, 0];
      private var page:int;
      private var wornFor:int = -1;

      /** petId(): the id of the 亚比 chosen in the bag (-1: none). */
      public function CardPage(petId:Function)
      {
         super();
         this.petId = petId;
         name = "petCardPage";
         var bg:Shape = new Shape();
         bg.graphics.beginFill(0xFFFFFF, 0.01);
         bg.graphics.drawRect(0, 0, W, H);
         bg.graphics.endFill();
         addChild(bg);
         var t:TextField = RUI.text(13, 0x0D5EB0, true);
         t.text = "战术卡";
         addChild(t);
         places.y = 22;
         addChild(places);
         addChild(RUI.well(0, 86, W, 124));
         list.x = 6;
         list.y = 92;
         addChild(list);
         var prev:Sprite = RUI.smallButton("◀", function():void { page--; drawList(); }, 26, 20, "petCardPrev");
         prev.x = 250;
         prev.y = 214;
         addChild(prev);
         pageText = RUI.text(12, 0x335577, false);
         pageText.x = 282;
         pageText.y = 215;
         addChild(pageText);
         var next:Sprite = RUI.smallButton("▶", function():void { page++; drawList(); }, 26, 20, "petCardNext");
         next.x = 318;
         next.y = 214;
         addChild(next);
         said = RUI.text(12, 0x5A4A2A, false, 240);
         said.y = 213;
         said.height = 36;
         addChild(said);
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("61_7", onMine);
         sc.addEventListener("54_25", onWorn);
         refresh();
      }

      /** Ask again: the cards one has, and those the 亚比 chosen wears. */
      public function refresh():void
      {
         SocketClient.instance.sendXtMessage("MaterialExtension", "61_7", {});
         var pid:int = int(petId());
         wornFor = pid;
         worn = [0, 0, 0];
         drawPlaces();
         if (pid > 0) SocketClient.instance.sendXtMessage("PetExtension", "54_25", {pid: pid, cid: 0});
      }

      public function dispose():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener("61_7", onMine);
         sc.removeEventListener("54_25", onWorn);
         if (parent != null) parent.removeChild(this);
      }

      private function onMine(e:SocketClientEvent):void
      {
         mine = (e.params.cards as Array || []).filter(function(c:Object, i:int, a:Array):Boolean { return card(int(c.id)) != null; });
         mine.sortOn("id", Array.NUMERIC);
         drawList();
      }

      private function onWorn(e:SocketClientEvent):void
      {
         var p:Object = e.params;
         if (int(p.pid) != wornFor) return;
         if (p.cards is Array) worn = (p.cards as Array).map(function(c:*, i:int, a:Array):int { return int(c); });
         drawPlaces();
         if (int(p.cid) == 0) return;
         said.text = String(p.msg || "");
         if (int(p.res) == 1)
         {
            SocketClient.instance.sendXtMessage("MaterialExtension", "61_7", {});
            // Its stats changed: the bag shows them from viewAllPM.
            PetClient.instance.viewAllPM();
         }
      }

      private function drawPlaces():void
      {
         while (places.numChildren > 0) places.removeChildAt(0);
         for (var i:int = 0; i < 3; i++)
         {
            var c:Object = worn[i] ? card(worn[i]) : null;
            var b:Sprite = box(114, 58, c != null ? 0xFFF4D6 : 0xEEF6FC);
            b.x = i * 123;
            b.name = "petCardPlace" + i;
            var t:TextField = RUI.text(12, 0x7A8A9A, true);
            t.text = TYPES[i] + "型";
            t.x = 6;
            t.y = 3;
            t.mouseEnabled = false;
            b.addChild(t);
            var n:TextField = RUI.text(12, c != null ? COLORS[int(c.color)] : 0x9AAAB8, c != null, 104);
            n.text = c != null ? String(c.name) : "没有装战术卡";
            n.x = 6;
            n.y = 22;
            n.mouseEnabled = false;
            b.addChild(n);
            if (c != null)
            {
               b.buttonMode = true;
               b.addEventListener(MouseEvent.CLICK, useFn(worn[i]));
               b.addEventListener(MouseEvent.ROLL_OVER, describeFn(worn[i], "（点击取下）"));
            }
            places.addChild(b);
         }
      }

      private function drawList():void
      {
         while (list.numChildren > 0) list.removeChildAt(0);
         var pages:int = Math.max(1, Math.ceil(mine.length / PER_PAGE));
         page = Math.max(0, Math.min(pages - 1, page));
         pageText.text = (page + 1) + "/" + pages;
         if (mine.length == 0)
         {
            var none:TextField = RUI.text(12, 0x5A7FA3, false, 340);
            none.text = "还没有战术卡。打败亚比BOSS的时候，有时会得到一张。";
            none.y = 8;
            list.addChild(none);
            return;
         }
         for (var i:int = 0; i < PER_PAGE && page * PER_PAGE + i < mine.length; i++)
         {
            var m:Object = mine[page * PER_PAGE + i];
            var c:Object = card(int(m.id));
            var b:Sprite = box(170, 26, 0xFFFFFF);
            b.x = (i % 2) * 176;
            b.y = int(i / 2) * 29;
            b.name = "petCard" + int(m.id);
            b.buttonMode = true;
            var t:TextField = RUI.text(12, COLORS[int(c.color)], true, 160);
            t.text = TYPES[int(c.type)] + " " + c.name + " ×" + int(m.qt);
            t.x = 4;
            t.y = 4;
            t.mouseEnabled = false;
            b.addChild(t);
            b.addEventListener(MouseEvent.CLICK, useFn(int(m.id)));
            b.addEventListener(MouseEvent.ROLL_OVER, describeFn(int(m.id), ""));
            list.addChild(b);
         }
      }

      private function useFn(id:int):Function
      {
         return function(e:MouseEvent):void
         {
            var pid:int = int(petId());
            if (pid <= 0)
            {
               said.text = "先选一只亚比。";
               return;
            }
            wornFor = pid;
            SocketClient.instance.sendXtMessage("PetExtension", "54_25", {pid: pid, cid: id});
         };
      }

      private function describeFn(id:int, more:String):Function
      {
         return function(e:MouseEvent):void
         {
            var c:Object = card(id);
            if (c != null) said.text = String(c.description) + more;
         };
      }

      private static function box(w:int, h:int, fill:uint):Sprite
      {
         var s:Sprite = new Sprite();
         s.graphics.lineStyle(1, 0x8CC8EF);
         s.graphics.beginFill(fill);
         s.graphics.drawRoundRect(0, 0, w, h, 10, 10);
         s.graphics.endFill();
         return s;
      }

      /** A card of the 2013 PetCardData (mmo.interfaces.material.petcard.PetCard), or null. */
      private static function card(id:int):Object
      {
         try { return Object(getDefinitionByName("mmo.materialdata.PetCardData")).data[String(id)]; }
         catch (e:Error) { RLog.error("cards: PetCardData", e); }
         return null;
      }
   }
}
