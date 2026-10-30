package mmo.play.scene
{
   import flash.geom.Point;

   /**
    * REBUILT. Finding a way round a scene's obstruction, for walkTo: a grid
    * of GRID-pixel cells marked walkable or not from the obstruction layer
    * (the later client keeps such a grid too, mmo.play.scene.pathfinder,
    * 8 neighbours, 10 straight and 14 diagonal), searched with A* and the
    * path pulled tight (a waypoint only where the straight line would cross
    * the obstruction).
    */
   public class PathGrid
   {
      public static const GRID:int = 10;

      private var w:int;
      private var h:int;
      private var cells:Vector.<int>; // 1 = blocked

      /** blocked(x, y): is this scene point on the obstruction? */
      public function PathGrid(width:int, height:int, blocked:Function)
      {
         w = Math.max(1, Math.ceil(width / GRID));
         h = Math.max(1, Math.ceil(height / GRID));
         cells = new Vector.<int>(w * h, true);
         for (var gy:int = 0; gy < h; gy++)
         {
            for (var gx:int = 0; gx < w; gx++)
            {
               cells[gy * w + gx] = blocked(gx * GRID + GRID / 2, gy * GRID + GRID / 2) ? 1 : 0;
            }
         }
      }

      private function free(gx:int, gy:int):Boolean
      {
         return gx >= 0 && gy >= 0 && gx < w && gy < h && cells[gy * w + gx] == 0;
      }

      private static function cell(v:Number):int
      {
         return int(v / GRID);
      }

      /** The free cell nearest (gx, gy), within radius cells; null when none. */
      private function nearestFree(gx:int, gy:int, radius:int):Point
      {
         if (free(gx, gy)) return new Point(gx, gy);
         var best:Point = null;
         var bestD:Number = Number.MAX_VALUE;
         for (var r:int = 1; r <= radius; r++)
         {
            for (var dy:int = -r; dy <= r; dy++)
            {
               for (var dx:int = -r; dx <= r; dx++)
               {
                  if (Math.abs(dx) != r && Math.abs(dy) != r) continue;
                  if (!free(gx + dx, gy + dy)) continue;
                  var d:Number = dx * dx + dy * dy;
                  if (d < bestD)
                  {
                     bestD = d;
                     best = new Point(gx + dx, gy + dy);
                  }
               }
            }
            if (best != null) return best;
         }
         return null;
      }

      /** Can one walk straight from (x0, y0) to (x1, y1) on free cells only? */
      public function lineFree(x0:Number, y0:Number, x1:Number, y1:Number):Boolean
      {
         var dist:Number = Math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
         var steps:int = Math.max(1, Math.ceil(dist / (GRID / 2)));
         for (var i:int = 0; i <= steps; i++)
         {
            if (!free(cell(x0 + (x1 - x0) * i / steps), cell(y0 + (y1 - y0) * i / steps))) return false;
         }
         return true;
      }

      /**
       * The waypoints from (x0, y0) to (x1, y1), the last one the destination
       * or, when that is on the obstruction, the nearest free point to it; null
       * when there is no way.
       */
      public function find(x0:Number, y0:Number, x1:Number, y1:Number):Array
      {
         var s:Point = nearestFree(cell(x0), cell(y0), 8);
         var e:Point = nearestFree(cell(x1), cell(y1), 40);
         if (s == null || e == null) return null;
         var endX:Number = free(cell(x1), cell(y1)) ? x1 : e.x * GRID + GRID / 2;
         var endY:Number = free(cell(x1), cell(y1)) ? y1 : e.y * GRID + GRID / 2;
         var startFree:Boolean = free(cell(x0), cell(y0));
         if (startFree && lineFree(x0, y0, endX, endY)) return [new Point(endX, endY)];

         var n:int = w * h;
         var g:Vector.<int> = new Vector.<int>(n, true);
         var from:Vector.<int> = new Vector.<int>(n, true);
         var closed:Vector.<Boolean> = new Vector.<Boolean>(n, true);
         for (var i:int = 0; i < n; i++) g[i] = int.MAX_VALUE;
         var start:int = s.y * w + s.x;
         var goal:int = e.y * w + e.x;
         g[start] = 0;
         from[start] = -1;
         var heap:Vector.<int> = new Vector.<int>();
         var fs:Vector.<int> = new Vector.<int>();
         push(heap, fs, start, heur(s.x, s.y, e.x, e.y));
         var DX:Array = [1, 0, -1, 0, 1, -1, -1, 1];
         var DY:Array = [0, 1, 0, -1, 1, 1, -1, -1];
         var found:Boolean = false;
         while (heap.length > 0)
         {
            var cur:int = pop(heap, fs);
            if (closed[cur]) continue;
            if (cur == goal)
            {
               found = true;
               break;
            }
            closed[cur] = true;
            var cx:int = cur % w;
            var cy:int = int(cur / w);
            for (var k:int = 0; k < 8; k++)
            {
               var nx:int = cx + DX[k];
               var ny:int = cy + DY[k];
               if (!free(nx, ny)) continue;
               // No cutting a corner of the obstruction.
               if (k >= 4 && (!free(cx + DX[k], cy) || !free(cx, cy + DY[k]))) continue;
               var ni:int = ny * w + nx;
               if (closed[ni]) continue;
               var ng:int = g[cur] + (k < 4 ? 10 : 14);
               if (ng < g[ni])
               {
                  g[ni] = ng;
                  from[ni] = cur;
                  push(heap, fs, ni, ng + heur(nx, ny, e.x, e.y));
               }
            }
         }
         if (!found) return null;
         var cellsPath:Array = [];
         for (var c:int = goal; c != -1; c = from[c]) cellsPath.unshift(new Point((c % w) * GRID + GRID / 2, int(c / w) * GRID + GRID / 2));
         cellsPath[cellsPath.length - 1] = new Point(endX, endY);
         // Pull tight: from each point, on to the farthest one in a straight free line.
         var out:Array = [];
         var px:Number = startFree ? x0 : cellsPath[0].x;
         var py:Number = startFree ? y0 : cellsPath[0].y;
         if (!startFree) out.push(cellsPath[0]);
         var at:int = 0;
         while (at < cellsPath.length - 1)
         {
            var next:int = at + 1;
            for (var j:int = cellsPath.length - 1; j > at + 1; j--)
            {
               if (lineFree(px, py, cellsPath[j].x, cellsPath[j].y))
               {
                  next = j;
                  break;
               }
            }
            out.push(cellsPath[next]);
            px = cellsPath[next].x;
            py = cellsPath[next].y;
            at = next;
         }
         if (out.length == 0) out.push(cellsPath[cellsPath.length - 1]);
         return out;
      }

      private static function heur(x0:int, y0:int, x1:int, y1:int):int
      {
         var dx:int = x0 > x1 ? x0 - x1 : x1 - x0;
         var dy:int = y0 > y1 ? y0 - y1 : y1 - y0;
         return dx > dy ? 14 * dy + 10 * (dx - dy) : 14 * dx + 10 * (dy - dx);
      }

      private static function push(heap:Vector.<int>, fs:Vector.<int>, v:int, f:int):void
      {
         heap.push(v);
         fs.push(f);
         var i:int = heap.length - 1;
         while (i > 0)
         {
            var p:int = (i - 1) >> 1;
            if (fs[p] <= fs[i]) break;
            var t:int = heap[p]; heap[p] = heap[i]; heap[i] = t;
            t = fs[p]; fs[p] = fs[i]; fs[i] = t;
            i = p;
         }
      }

      private static function pop(heap:Vector.<int>, fs:Vector.<int>):int
      {
         var top:int = heap[0];
         var lastV:int = heap.pop();
         var lastF:int = fs.pop();
         if (heap.length > 0)
         {
            heap[0] = lastV;
            fs[0] = lastF;
            var i:int = 0;
            var n:int = heap.length;
            while (true)
            {
               var l:int = 2 * i + 1;
               var r:int = l + 1;
               var m:int = i;
               if (l < n && fs[l] < fs[m]) m = l;
               if (r < n && fs[r] < fs[m]) m = r;
               if (m == i) break;
               var t:int = heap[m]; heap[m] = heap[i]; heap[i] = t;
               t = fs[m]; fs[m] = fs[i]; fs[i] = t;
               i = m;
            }
         }
         return top;
      }
   }
}
