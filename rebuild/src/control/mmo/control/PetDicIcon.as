package mmo.control
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.system.ApplicationDomain;
   import flash.utils.getDefinitionByName;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.revival.RLog;

   /**
    * REVIVAL. The 图鉴's icon of 2012 on the bar: the blue book with the sprout, as the
    * garden's own bar shows it. The control bar it stood on (2012–13) is lost and no
    * other SWF carries the icon alone, so it is taken from the era tutorial picture
    * of the garden (house/houseteachmovie/houseteachgarden, January 2012, the icon at
    * the top right) and cut out of the sky behind it: the sky is passed over from
    * the edges up to the icon's white and dark outlines, and what is left (its
    * largest part) is the icon. Until the picture is loaded, or if it is not, the
    * bar keeps the icon it draws.
    */
   public class PetDicIcon
   {
      private static const SRC:String = "house/houseteachmovie/houseteachgarden";
      private static const CLS:String = "mmo.houseteachgarden.GardenTeachMovie";
      /** The icon's square in the picture. */
      private static const X0:int = 772, Y0:int = 6, W:int = 50, H:int = 48;
      /** The sky around it. */
      private static const SKY_R:int = 0xA8, SKY_G:int = 0xE4, SKY_B:int = 0xFA, SKY_NEAR:int = 40;

      /** The picture's icon in place of what into draws (centred on into's origin). */
      public static function put(into:Sprite):void
      {
         var go:Function = function(d:* = null):void
         {
            if (!ApplicationDomain.currentDomain.hasDefinition(CLS)) return;
            try
            {
               var mc:MovieClip = new (getDefinitionByName(CLS) as Class)() as MovieClip;
               mc.stop();
               var picture:DisplayObject = mc.getChildAt(0);
               var bd:BitmapData = new BitmapData(W, H, true, 0);
               bd.draw(picture, new Matrix(1, 0, 0, 1, -X0, -Y0));
               if (!cut(bd)) return;
               var b:Bitmap = new Bitmap(bd, "auto", true);
               b.x = -W / 2;
               b.y = -H / 2 - 2;
               into.graphics.clear();
               while (into.numChildren > 0) into.removeChildAt(0);
               into.addChild(b);
            }
            catch (e:Error) { RLog.error("图鉴 icon", e); }
         };
         if (ApplicationDomain.currentDomain.hasDefinition(CLS)) go();
         else ResScheduler.getResource(SRC, go, CLS, function(e:* = null):void { RLog.log("图鉴 icon: no picture"); });
      }

      /** The sky made clear; false if nothing like the icon is left. */
      private static function cut(bd:BitmapData):Boolean
      {
         var n:int = W * H;
         var sky:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         var q:Vector.<int> = new Vector.<int>();
         var i:int, x:int, y:int;
         for (x = 0; x < W; x++) { q.push(x); q.push((H - 1) * W + x); }
         for (y = 0; y < H; y++) { q.push(y * W); q.push(y * W + W - 1); }
         var head:int = 0;
         while (head < q.length)
         {
            i = q[head++];
            if (sky[i] || outline(bd.getPixel(i % W, int(i / W)))) continue;
            sky[i] = true;
            x = i % W;
            y = int(i / W);
            if (x > 0 && !sky[i - 1]) q.push(i - 1);
            if (x < W - 1 && !sky[i + 1]) q.push(i + 1);
            if (y > 0 && !sky[i - W]) q.push(i - W);
            if (y < H - 1 && !sky[i + W]) q.push(i + W);
         }
         // The largest part left is the icon (specks of the clouds' edges go).
         var part:Vector.<int> = new Vector.<int>(n, true);
         var best:int = 0, bestSize:int = 0, id:int = 0;
         for (var s:int = 0; s < n; s++)
         {
            if (sky[s] || part[s] != 0) continue;
            id++;
            var size:int = 0;
            q.length = 0;
            q.push(s);
            part[s] = id;
            head = 0;
            while (head < q.length)
            {
               i = q[head++];
               size++;
               x = i % W;
               y = int(i / W);
               for each (var j:int in [x > 0 ? i - 1 : -1, x < W - 1 ? i + 1 : -1, y > 0 ? i - W : -1, y < H - 1 ? i + W : -1])
               {
                  if (j < 0 || sky[j] || part[j] != 0) continue;
                  part[j] = id;
                  q.push(j);
               }
            }
            if (size > bestSize) { bestSize = size; best = id; }
         }
         if (bestSize < n / 4) return false;
         bd.lock();
         for (i = 0; i < n; i++)
            if (part[i] != best) bd.setPixel32(i % W, int(i / W), 0);
         bd.unlock();
         return true;
      }

      /** Where the sky stops: the icon's white rim and dark line (but not the sky itself). */
      private static function outline(rgb:uint):Boolean
      {
         var r:int = (rgb >> 16) & 0xFF, g:int = (rgb >> 8) & 0xFF, b:int = rgb & 0xFF;
         if (Math.abs(r - SKY_R) + Math.abs(g - SKY_G) + Math.abs(b - SKY_B) < SKY_NEAR) return false;
         var hi:int = Math.max(r, Math.max(g, b)), lo:int = Math.min(r, Math.min(g, b));
         return hi < 100 || lo >= 200;
      }
   }
}
