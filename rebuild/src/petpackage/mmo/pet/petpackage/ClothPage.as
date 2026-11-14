package mmo.pet.petpackage
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import mmo.common.utils.tips.TipsManager;
   import mmo.common.viewloader.ViewLoader;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.avatar.IAlbumAvatarProxy;
   import mmo.interfaces.avatar.IAvatarService;
   import mmo.interfaces.material.clothes.AvatarInfo;
   import mmo.interfaces.material.clothes.IClothesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PetClothesMap;
   import mmo.interfaces.pet.data.PetDressInfosMap;
   import mmo.loader.layer.LayerManager;
   import mmo.revival.RLog;
   import mmo.revival.RNotice;

   /**
    * REVIVAL 亚比装扮 (the bag's 装扮 tab; the 2011 dressing panel, pet/petdress's
    * mmo.pet.petdress.view.dress.PetDressPanel, is lost), laid out as the 道具 tab: the
    * pieces one has (the 2013 ClothesData's PetClothes 30001–30011, each for one 亚比, the ten
    * of PetDressInfosMap) in the 道具 page's squares (PetItem.createGrid / createSquare), each
    * with its picture, how many one has and, on the 亚比 chosen, 穿着; its name and words as the
    * tip. A click puts it on the 亚比 chosen, or takes it off. The bag stands the 亚比 on the blue
    * platform (dressEffect, dressBottom) in what it wears (figure: the album avatar of its
    * walking figure and the pieces, skinview/). The server: MaterialExtension 61_5 (the pieces
    * one has) and PetExtension 54_24 {pi, dr} (petdress.ts).
    */
   public class ClothPage extends Sprite
   {
      /** The pet clothes of the 2013 ClothesData. */
      private static const IDS:Array = [30001, 30002, 30003, 30004, 30005, 30006, 30007, 30008, 30009, 30010, 30011];
      private static const PER_PAGE:int = 20;
      /** What a 亚比 wears, as the server last said it this session: pet id -> "30002;30003". */
      private static var worn:Object = {};

      private var grid:DisplayObjectContainer;
      private var square:Function;
      private var pet:Function;
      private var onDressed:Function;
      private var box:Sprite = new Sprite();
      /** The pieces one has: [id, how many], in id order. */
      private var mine:Array = [];
      private var page:int;
      private var asked:int = -1;

      /**
       * grid: the 道具 page's art (p_0…p_19, prevBtn, nextBtn, pageTxt); square(): one of its
       * squares (txtNum); pet(): the 亚比 chosen in the bag (PetBriefInfo or null);
       * onDressed(): it put something on or took it off.
       */
      public function ClothPage(grid:DisplayObjectContainer, square:Function, pet:Function, onDressed:Function)
      {
         super();
         this.grid = grid;
         this.square = square;
         this.pet = pet;
         this.onDressed = onDressed;
         name = "petClothPage";
         addChild(grid);
         grid.addChild(box);
         var prev:DisplayObject = grid.getChildByName("prevBtn");
         var next:DisplayObject = grid.getChildByName("nextBtn");
         if (prev) prev.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { page--; draw(); });
         if (next) next.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void { page++; draw(); });
         var sc:SocketClient = SocketClient.instance;
         sc.addEventListener("61_5", onMine);
         sc.addEventListener("54_24", onWorn);
         refresh();
      }

      /** Whether a 亚比 of this view can wear anything (PetDressInfosMap). */
      public static function canDress(viewId:int):Boolean
      {
         try { return PetDressInfosMap.instance.isAbleToBeDress(viewId); }
         catch (e:Error) { RLog.error("dress: PetDressInfosMap", e); }
         return false;
      }

      /** What the 亚比 wears: the server's answer this session, else its pmSView "drs". */
      public static function drsOf(p:PetBriefInfo):String
      {
         if (p == null) return "";
         if (worn.hasOwnProperty(String(p.id))) return String(worn[String(p.id)]);
         try { return String(Object(p).drs || ""); } catch (e:Error) {}
         return "";
      }

      /**
       * The 亚比 as its big picture with what it wears (the album avatar: skinview/ of its
       * walking figure, PetClothesMap, and of each piece), standing on (cx, cy) and at most
       * fit high. Returns the sprite (null: no walking figure or no avatar service).
       */
      public static function figure(into:DisplayObjectContainer, p:PetBriefInfo, cx:Number, cy:Number, fit:Number):Sprite
      {
         var walk:int = PetClothesMap.getClothesId(p.viewId);
         if (walk <= 0) return null;
         var sp:Sprite;
         try
         {
            var proxy:IAlbumAvatarProxy = (ServiceContainer.getService(IAvatarService) as IAvatarService).getAlbumAvatarProxy(false);
            var info:AvatarInfo = new AvatarInfo();
            var drs:String = drsOf(p);
            info.setAvatarInfoWithString(walk + (drs != "" ? ";" + drs : ""));
            proxy.setAvatarInfo(info);
            sp = proxy.getSprite();
         }
         catch (e:Error)
         {
            RLog.error("dress: figure of 亚比 " + p.viewId, e);
            return null;
         }
         sp.name = "revivalIcon";
         sp.mouseEnabled = sp.mouseChildren = false;
         into.addChild(sp);
         // Its pieces come one by one: fitted again while its size changes, for two seconds.
         var frames:int = 0;
         var last:String = "";
         var each:Function = function(e:Event):void
         {
            if (sp.parent == null || ++frames > 60) { sp.removeEventListener(Event.ENTER_FRAME, each); return; }
            var sx:Number = sp.scaleX;
            sp.scaleX = sp.scaleY = 1;
            var b:Rectangle = sp.getBounds(sp);
            sp.scaleX = sp.scaleY = sx;
            if (b.height <= 1) return;
            var key:String = [b.x, b.y, b.width, b.height].join();
            if (key == last) return;
            last = key;
            var k:Number = Math.min(2.2, fit / b.height, 170 / Math.max(1, b.width));
            sp.scaleX = sp.scaleY = k;
            sp.x = cx - (b.x + b.width / 2) * k;
            sp.y = cy - b.bottom * k;
         };
         sp.addEventListener(Event.ENTER_FRAME, each);
         return sp;
      }

      /** Ask again for the pieces one has; draw them for the 亚比 chosen. */
      public function refresh():void
      {
         SocketClient.instance.sendXtMessage("MaterialExtension", "61_5", {});
         draw();
      }

      public function dispose():void
      {
         var sc:SocketClient = SocketClient.instance;
         sc.removeEventListener("61_5", onMine);
         sc.removeEventListener("54_24", onWorn);
         if (parent != null) parent.removeChild(this);
      }

      private function onMine(e:SocketClientEvent):void
      {
         mine = [];
         for each (var o:Object in e.params.pd as Array || [])
         {
            if (IDS.indexOf(int(o.id)) >= 0 && int(o.qt) > 0) mine.push([int(o.id), int(o.qt)]);
         }
         mine.sortOn("0", Array.NUMERIC);
         draw();
      }

      private function onWorn(e:SocketClientEvent):void
      {
         var r:Object = e.params;
         if (int(r.pi) != asked) return;
         worn[String(r.pi)] = String(r.dr || "");
         draw();
         if (int(r.res) != 1)
         {
            if (r.msg) RNotice.show(LayerManager.getBaseTop(), String(r.msg));
            return;
         }
         SocketClient.instance.sendXtMessage("MaterialExtension", "61_5", {});
         if (onDressed != null) onDressed();
      }

      /** The PetClothes of id (name, raceId, description), or null. */
      private static function piece(id:int):Object
      {
         try { return (ServiceContainer.getService(IClothesService) as IClothesService).getClothesDataById(id); }
         catch (e:Error) { RLog.error("dress: clothes " + id, e); }
         return null;
      }

      private function draw():void
      {
         while (box.numChildren > 0) box.removeChildAt(0);
         var pages:int = Math.max(1, Math.ceil(mine.length / PER_PAGE));
         page = Math.max(0, Math.min(pages - 1, page));
         var txt:TextField = grid.getChildByName("pageTxt") as TextField;
         if (txt) txt.text = (page + 1) + "/" + pages;
         var p:PetBriefInfo = pet() as PetBriefInfo;
         var on:Array = drsOf(p) == "" ? [] : drsOf(p).split(";");
         for (var i:int = 0; i < PER_PAGE && page * PER_PAGE + i < mine.length; i++)
         {
            var id:int = int(mine[page * PER_PAGE + i][0]);
            var have:int = int(mine[page * PER_PAGE + i][1]);
            var slot:DisplayObject = grid.getChildByName("p_" + i);
            var s:Sprite = square() as Sprite;
            if (s == null) continue;
            s.name = "petCloth" + id;
            s.x = slot ? slot.x : (i % 5) * 67;
            s.y = slot ? slot.y : int(i / 5) * 59;
            // The whole square answers the pointer, before (and around) the picture.
            s.graphics.beginFill(0, 0);
            s.graphics.drawRect(0, 0, 55, 55);
            s.graphics.endFill();
            var c:Object = piece(id);
            var pic:DisplayObject = icon(c);
            if (pic != null)
            {
               pic.x = 5;
               pic.y = 3;
               s.addChildAt(pic, 0);
            }
            var num:TextField = s.getChildByName("txtNum") as TextField;
            if (num) num.text = String(have);
            var wearing:Boolean = on.indexOf(String(id)) >= 0;
            if (wearing) s.addChild(wornMark());
            if (c != null) TipsManager.getInstance().addComplexTips(s, String(c.name), String(c.description || ""));
            s.buttonMode = true;
            s.mouseChildren = false;
            s.addEventListener(MouseEvent.CLICK, wearFn(id, !wearing));
            box.addChild(s);
         }
      }

      /** 穿着, on a square the 亚比 chosen wears. */
      private static function wornMark():TextField
      {
         var t:TextField = new TextField();
         t.defaultTextFormat = new TextFormat("SimSun", 12, 0x1E8A1E, true);
         t.autoSize = TextFieldAutoSize.LEFT;
         t.selectable = false;
         t.mouseEnabled = false;
         t.text = "穿着";
         t.filters = [new GlowFilter(0xFFFFFF, 1, 3, 3, 8)];
         t.x = 1;
         t.y = 0;
         return t;
      }

      private function wearFn(id:int, put:Boolean):Function
      {
         return function(e:MouseEvent):void
         {
            var p:PetBriefInfo = pet() as PetBriefInfo;
            if (p == null) return;
            var on:Array = drsOf(p) == "" ? [] : drsOf(p).split(";");
            on = on.filter(function(x:String, i:int, a:Array):Boolean { return x != "" && x != String(id); });
            if (put) on.push(String(id));
            asked = p.id;
            SocketClient.instance.sendXtMessage("PetExtension", "54_24", {pi: p.id, dr: on.join(";")});
         };
      }

      /**
       * A piece's picture in a square, 45 across, as the 道具 page has an item's: the
       * ClothesViewCreator's (skinicon/<file>, class <its first part>_A), through ViewLoader.
       */
      private static function icon(c:Object):DisplayObject
      {
         if (c == null || c.parts == null || c.parts.length == 0) return null;
         try { return ViewLoader.instance.getViewCustom(String(c.parts[0].clothesNo) + "_A", "skinicon/" + String(c.fileName), 45, 45); }
         catch (e:Error) { RLog.error("dress: icon " + c.id, e); }
         return null;
      }
   }
}
