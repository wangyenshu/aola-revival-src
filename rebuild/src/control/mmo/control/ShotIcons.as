package mmo.control
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;

   /**
    * REVIVAL. The control bar's icons of 2012 in place of the drawn ones (BarIcons), as PetDicIcon
    * does for the 图鉴: the bar of 2012–13 was in the lost control/control.swf, and no surviving
    * file carries its icons alone. The era tutorial of the 家园 house/houseteachmovie/houseteachhouse
    * (March 2012) has two screenshots of the game: the house with the bar (发言 表情 动作 射击, 信息卡
    * 好友 组队 战队 亚比 回家), and the 家园's 亚比 bar with the corner of the 商城's cart. Each icon is
    * cut out of its screenshot at load:
    *   on the bar, what is like the bar or the room behind it (each row's colour, from the strips
    *   just left and right of the icon) is passed over from the edges up to the icon's outline, and
    *   the largest part left, without its thin bits (the room's posts, the bar's edge), is the icon;
    *   the cart (on the corner's light panel and the blue bar) is its warm colours and their outline.
    * Until the tutorial is loaded, or if it is not, the bar keeps the icons it draws.
    */
   public class ShotIcons
   {
      private static const SRC:String = "house/houseteachmovie/houseteachhouse";
      private static const CLS:String = "mmo.houseteachmovie.House";
      /** The tutorial's frames showing the house (with the bar) and the 家园's bar (with the cart). */
      private static const FRAME_BAR:int = 30, FRAME_CART:int = 1;
      /** name -> [frame, x0, x1, y0, y1, warm] in the 960×560 screenshot. */
      private static const AREAS:Object = {
         phrase: [FRAME_BAR, 161, 206, 503, 554, false],
         face: [FRAME_BAR, 206, 250, 503, 554, false],
         action: [FRAME_BAR, 251, 292, 503, 554, false],
         shoot: [FRAME_BAR, 293, 335, 514, 554, false],
         card: [FRAME_BAR, 578, 615, 503, 554, false],
         friend: [FRAME_BAR, 618, 663, 503, 554, false],
         team: [FRAME_BAR, 663, 715, 503, 554, false],
         squad: [FRAME_BAR, 715, 764, 503, 554, false],
         pet: [FRAME_BAR, 764, 812, 503, 554, false],
         home: [FRAME_BAR, 813, 866, 503, 554, false],
         mall: [FRAME_CART, 910, 960, 482, 540, true]
      };
      /** How near a pixel is to the row behind it to be passed over (|dr|+|dg|+|db|). */
      private static const NEAR:int = 40;

      private static var waiting:Array = [];
      private static var movie:MovieClip;
      private static var asked:Boolean;

      /** The screenshot's icon `name` in place of what into draws (centred on into's origin). */
      public static function put(name:String, into:Sprite):void
      {
         if (AREAS[name] == null) return;
         waiting.push([name, into]);
         if (movie != null) { flush(); return; }
         if (asked) return;
         asked = true;
         var go:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(CLS)) return;
            try
            {
               movie = new (getDefinitionByName(CLS) as Class)() as MovieClip;
               movie.stop();
               flush();
            }
            catch (e:Error) { RLog.error("bar icons", e); }
         };
         if (ApplicationDomain.currentDomain.hasDefinition(CLS)) go();
         else ResScheduler.getResource(SRC, go, CLS, function(e:* = null):void { RLog.log("bar icons: no tutorial"); });
      }

      private static function flush():void
      {
         var list:Array = waiting;
         waiting = [];
         for each (var w:Array in list)
         {
            try
            {
               var a:Array = AREAS[w[0]];
               movie.gotoAndStop(a[0]);
               var icon:BitmapData = a[5] ? cutWarm(movie, a[1], a[2], a[3], a[4]) : cutBar(movie, a[1], a[2], a[3], a[4]);
               if (icon != null) show(w[1], icon);
            }
            catch (e:Error) { RLog.error("bar icon " + w[0], e); }
         }
      }

      /** The icon centred on into's origin, in place of its drawing. */
      private static function show(into:Sprite, bd:BitmapData):void
      {
         var r:flash.geom.Rectangle = bd.getColorBoundsRect(0xFF000000, 0x00000000, false);
         if (r.width < 4 || r.height < 4) return;
         var b:Bitmap = new Bitmap(bd, "auto", true);
         b.x = -Math.round(r.x + r.width / 2);
         b.y = -Math.round(r.y + r.height / 2);
         into.graphics.clear();
         while (into.numChildren > 0) into.removeChildAt(0);
         into.addChild(b);
      }

      /** The area with two columns more on each side (the strips the rows' colours come from). */
      private static function grab(mc:MovieClip, x0:int, x1:int, y0:int, y1:int, extra:int):BitmapData
      {
         var bd:BitmapData = new BitmapData(x1 - x0 + 2 * extra, y1 - y0, false, 0);
         bd.draw(mc, new Matrix(1, 0, 0, 1, -(x0 - extra), -y0));
         return bd;
      }

      private static function cutBar(mc:MovieClip, x0:int, x1:int, y0:int, y1:int):BitmapData
      {
         var src:BitmapData = grab(mc, x0, x1, y0, y1, 2);
         var W:int = x1 - x0, H:int = y1 - y0, n:int = W * H;
         var i:int, x:int, y:int, c:uint;
         // Each row's colour behind the icon, from x0-2..x0-1 to x1..x1+1, across.
         var bg:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         var q:Vector.<int> = new Vector.<int>();
         for (x = 0; x < W; x++) { q.push(x); q.push((H - 1) * W + x); }
         for (y = 0; y < H; y++) { q.push(y * W); q.push(y * W + W - 1); }
         var head:int = 0;
         while (head < q.length)
         {
            i = q[head++];
            if (bg[i]) continue;
            x = i % W;
            y = int(i / W);
            if (!behind(src, x, y, W)) continue;
            bg[i] = true;
            if (x > 0 && !bg[i - 1]) q.push(i - 1);
            if (x < W - 1 && !bg[i + 1]) q.push(i + 1);
            if (y > 0 && !bg[i - W]) q.push(i - W);
            if (y < H - 1 && !bg[i + W]) q.push(i + W);
         }
         var keep:Vector.<Boolean> = largest(bg, W, H, true);
         if (keep == null) return null;
         keep = slim(keep, W, H);
         if (keep == null) return null;
         var out:BitmapData = new BitmapData(W, H, true, 0);
         for (i = 0; i < n; i++)
            if (keep[i]) out.setPixel32(i % W, int(i / W), 0xFF000000 | src.getPixel(i % W + 2, int(i / W)));
         return out;
      }

      /** Is the pixel like its row behind the icon (the strips' colours, from left to right)? */
      private static function behind(src:BitmapData, x:int, y:int, W:int):Boolean
      {
         var l1:uint = src.getPixel(0, y), l2:uint = src.getPixel(1, y), r1:uint = src.getPixel(W + 2, y), r2:uint = src.getPixel(W + 3, y);
         var t:Number = x / Math.max(1, W);
         var d:Number = 0;
         for (var s:int = 16; s >= 0; s -= 8)
         {
            var l:Number = (((l1 >> s) & 0xFF) + ((l2 >> s) & 0xFF)) / 2;
            var r:Number = (((r1 >> s) & 0xFF) + ((r2 >> s) & 0xFF)) / 2;
            d += Math.abs(((src.getPixel(x + 2, y) >> s) & 0xFF) - (l * (1 - t) + r * t));
         }
         return d < NEAR;
      }

      /** The cart: its warm colours (red well over blue), and round them its outline and lights. */
      private static function cutWarm(mc:MovieClip, x0:int, x1:int, y0:int, y1:int):BitmapData
      {
         var src:BitmapData = grab(mc, x0, x1, y0, y1, 0);
         var W:int = x1 - x0, H:int = y1 - y0, n:int = W * H;
         var i:int, x:int, y:int;
         var cold:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         for (i = 0; i < n; i++) cold[i] = warmth(src.getPixel(i % W, int(i / W))) <= 50;
         var keep:Vector.<Boolean> = largest(cold, W, H, false);
         if (keep == null) return null;
         for (var k:int = 0; k < 2; k++)
         {
            var grown:Vector.<Boolean> = keep.concat();
            for (i = 0; i < n; i++)
            {
               if (keep[i]) continue;
               x = i % W;
               y = int(i / W);
               if (!near(keep, x, y, W, H)) continue;
               var c:uint = src.getPixel(x, y);
               var hi:int = Math.max((c >> 16) & 0xFF, Math.max((c >> 8) & 0xFF, c & 0xFF));
               if (hi < 110 || warmth(c) > 35) grown[i] = true;
            }
            keep = grown;
         }
         var out:BitmapData = new BitmapData(W, H, true, 0);
         for (i = 0; i < n; i++)
            if (keep[i]) out.setPixel32(i % W, int(i / W), 0xFF000000 | src.getPixel(i % W, int(i / W)));
         return out;
      }

      private static function warmth(c:uint):int
      {
         return ((c >> 16) & 0xFF) - (c & 0xFF);
      }

      private static function near(m:Vector.<Boolean>, x:int, y:int, W:int, H:int):Boolean
      {
         for (var dy:int = -1; dy <= 1; dy++)
            for (var dx:int = -1; dx <= 1; dx++)
            {
               var xx:int = x + dx, yy:int = y + dy;
               if (xx >= 0 && yy >= 0 && xx < W && yy < H && m[yy * W + xx]) return true;
            }
         return false;
      }

      /** The largest 4-connected part of the pixels not passed over (null if it is too small). */
      private static function largest(off:Vector.<Boolean>, W:int, H:int, quarter:Boolean):Vector.<Boolean>
      {
         var n:int = W * H;
         var part:Vector.<int> = new Vector.<int>(n, true);
         var q:Vector.<int> = new Vector.<int>();
         var best:int = 0, bestSize:int = 0, id:int = 0;
         for (var s:int = 0; s < n; s++)
         {
            if (off[s] || part[s] != 0) continue;
            id++;
            var size:int = 0;
            q.length = 0;
            q.push(s);
            part[s] = id;
            var head:int = 0;
            while (head < q.length)
            {
               var i:int = q[head++];
               size++;
               var x:int = i % W, y:int = int(i / W);
               for each (var j:int in [x > 0 ? i - 1 : -1, x < W - 1 ? i + 1 : -1, y > 0 ? i - W : -1, y < H - 1 ? i + W : -1])
               {
                  if (j < 0 || off[j] || part[j] != 0) continue;
                  part[j] = id;
                  q.push(j);
               }
            }
            if (size > bestSize) { bestSize = size; best = id; }
         }
         if (bestSize < (quarter ? n / 4 : n / 8)) return null;
         var keep:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         for (i = 0; i < n; i++) keep[i] = part[i] == best;
         return keep;
      }

      /** Without thin bits: eroded once, its largest part grown back twice inside the first. */
      private static function slim(m:Vector.<Boolean>, W:int, H:int):Vector.<Boolean>
      {
         var n:int = W * H;
         var er:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         var notEr:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         for (var i:int = 0; i < n; i++)
         {
            var x:int = i % W, y:int = int(i / W);
            var all:Boolean = m[i];
            for (var dy:int = -1; all && dy <= 1; dy++)
               for (var dx:int = -1; all && dx <= 1; dx++)
               {
                  var xx:int = x + dx, yy:int = y + dy;
                  all = xx >= 0 && yy >= 0 && xx < W && yy < H && m[yy * W + xx];
               }
            er[i] = all;
            notEr[i] = !all;
         }
         var keep:Vector.<Boolean> = largest(notEr, W, H, false);
         if (keep == null) return m;
         for (var k:int = 0; k < 2; k++)
         {
            var grown:Vector.<Boolean> = keep.concat();
            for (i = 0; i < n; i++)
               if (!keep[i] && m[i] && near(keep, i % W, int(i / W), W, H)) grown[i] = true;
            keep = grown;
         }
         return keep;
      }
   }
}
