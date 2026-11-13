package mmo.petfightnew
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.MouseEvent;
   import flash.filters.BitmapFilterQuality;
   import flash.filters.GlowFilter;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import mmo.loader.scheduler.VersManager;

   /**
    * REVIVAL. A 亚比's 异常状态 as icons in a row, as the later battle module draws them
    * (NewStatusIconList, StatusIcon, StatusIconHandler): each status's picture
    * pet/status/statusicon_<frame>.png (its frame by StatusUtil's table: 睡眠 1, 中毒 2, 害怕 3,
    * 诅咒 4, 麻痹 5, 混乱 6, 冰冻 7, 寄生种子 8, 烧伤 9, 束缚 10, 衰弱 16) at 22×20, 2 apart, the
    * rounds left on it in white when 1 to 29, and a tip with its name and words (its _tipsArr and
    * _detailTipsArr, where they say what the battle here does) and 剩余持续回合数.
    */
   public class StatusIcons extends Sprite
   {
      public static const W:int = 22;
      public static const H:int = 20;
      private static const GAP:int = 2;

      private static const FRAMES:Object = {"睡眠": 1, "中毒": 2, "害怕": 3, "诅咒": 4, "麻痹": 5, "混乱": 6, "冰冻": 7, "寄生": 8, "烧伤": 9, "束缚": 10, "衰弱": 16};
      private static const WORDS:Object = {
         "睡眠": "睡眠中不能行动",
         "中毒": "每回合扣除1/8最大体力值",
         "害怕": "当回合无法行动",
         "诅咒": "每回合扣除1/4最大体力值",
         "麻痹": "有一定机率无法行动",
         "混乱": "有一定机率攻击自身",
         "冰冻": "冰冻中不能行动",
         "寄生": "每回合被吸取1/8最大体力值，对木系无效",
         "烧伤": "每回合扣除1/8最大体力值",
         "束缚": "每回合扣除1/16最大体力值，并且不可更换宠物",
         "衰弱": "每回合扣除的体力值效果加剧"
      };
      private static var cache:Object = {};

      /** Shows the tip: (title, words, the icon). */
      private var tip:Function;
      private var hide:Function;
      private var key:String = "";
      /** Whether one of these icons' tip is up (taken down when the icons change under it). */
      private var tipUp:Boolean = false;

      public function StatusIcons(tip:Function, hide:Function)
      {
         super();
         this.tip = tip;
         this.hide = hide;
      }

      /** Whether a status has an icon (the others stay words by the name). */
      public static function hasIcon(name:String):Boolean
      {
         return FRAMES[name] != null;
      }

      /** list: [[name, rounds left (0: till cured)], …] (pmSView.sts). */
      public function show(list:Array):void
      {
         var k:String = list ? list.join(";") : "";
         if (k == key) return;
         key = k;
         // A tip up over the icons that change: down, and up again for the icon the mouse is now over.
         var again:Boolean = tipUp;
         if (tipUp)
         {
            tipUp = false;
            hide();
         }
         while (numChildren) removeChildAt(0);
         if (list == null) return;
         var n:int = 0;
         for each (var it:Array in list)
         {
            var name:String = String(it[0]);
            if (!hasIcon(name)) continue;
            var icon:Sprite = make(name, int(it[1]));
            icon.x = n * (W + GAP);
            addChild(icon);
            n++;
         }
         if (again && stage)
         {
            for (var i:int = 0; i < numChildren; i++)
            {
               if (!getChildAt(i).hitTestPoint(stage.mouseX, stage.mouseY)) continue;
               getChildAt(i).dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
               break;
            }
         }
      }

      public function get count():int
      {
         return numChildren;
      }

      private function make(name:String, left:int):Sprite
      {
         var icon:Sprite = new Sprite();
         icon.name = "status_" + name;
         icon.graphics.beginFill(0, 0);
         icon.graphics.drawRect(0, 0, W, H);
         icon.graphics.endFill();
         var frame:int = int(FRAMES[name]);
         var put:Function = function(bd:BitmapData):void
         {
            var bm:Bitmap = new Bitmap(bd);
            bm.width = W;
            bm.height = H;
            icon.addChildAt(bm, 0);
         };
         if (cache[frame]) put(cache[frame]);
         else
         {
            var ld:Loader = new Loader();
            ld.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
            {
               var b:Bitmap = ld.content as Bitmap;
               if (b == null) return;
               if (cache[frame] == null) cache[frame] = b.bitmapData;
               put(cache[frame]);
            });
            ld.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event):void {});
            try { ld.load(VersManager.getVerURLRequest("pet/status/statusicon_" + frame + ".png")); } catch (err:Error) {}
         }
         if (left > 0 && left < 30)
         {
            var t:TextField = new TextField();
            t.mouseEnabled = false;
            t.selectable = false;
            t.defaultTextFormat = new TextFormat("宋体", 12, 0xFFFFFF, true, null, null, null, null, "right");
            t.x = 2;
            t.y = 4;
            t.width = 22;
            t.height = 18;
            t.filters = [new GlowFilter(0x122D64, 1, 2, 2, 4, BitmapFilterQuality.MEDIUM)];
            t.text = String(left);
            icon.addChild(t);
         }
         var words:String = String(WORDS[name] || "") + (left > 0 ? "\n剩余持续回合数：" + left : "");
         icon.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void { tipUp = true; tip(name, words, icon); });
         icon.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void { tipUp = false; hide(); });
         return icon;
      }
   }
}
