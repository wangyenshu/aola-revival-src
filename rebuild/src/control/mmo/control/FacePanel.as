package mmo.control
{
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.geom.Rectangle;
   import mmo.interfaces.face.IFaceService;

   /**
    * REBUILT 表情 (the 表情 button): the faces of baseservice/face
    * (IFaceService.getFaceIds, getFace) in a grid; pointing at one plays it,
    * a click shows it over my head for everyone in the scene
    * (SceneTalkService.smile → "[Emote]").
    */
   public class FacePanel extends Sprite
   {
      private static const CELL:int = 40;
      private static const COLS:int = 6;

      public var onFace:Function;

      public function FacePanel(faces:IFaceService)
      {
         super();
         var ids:Array = faces ? faces.getFaceIds() : [];
         var rows:int = Math.max(1, Math.ceil(ids.length / COLS));
         BarSkin.panel(graphics, 0, 0, COLS * CELL + 16, rows * CELL + 16, 14);
         for (var i:int = 0; i < ids.length; i++)
         {
            var c:Sprite = cell(int(ids[i]));
            c.x = 8 + (i % COLS) * CELL;
            c.y = 8 + int(i / COLS) * CELL;
            addChild(c);
            load(faces, int(ids[i]), c);
         }
      }

      private function cell(id:int):Sprite
      {
         var c:Sprite = new Sprite();
         c.name = "face" + id;
         var g:Graphics = c.graphics;
         var draw:Function = function(over:Boolean):void
         {
            g.clear();
            g.lineStyle(1, over ? 0xF0A000 : 0x9FD0EE);
            g.beginFill(over ? 0xFFF3C4 : 0xFFFFFF, over ? 1 : 0.55);
            g.drawRoundRect(2, 2, CELL - 4, CELL - 4, 10, 10);
            g.endFill();
         };
         draw(false);
         c.buttonMode = true;
         c.mouseChildren = false;
         c.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void
         {
            draw(true);
            var mc:MovieClip = c.numChildren > 0 ? c.getChildAt(0) as MovieClip : null;
            if (mc) mc.gotoAndPlay(1);
         });
         c.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void
         {
            draw(false);
            var mc:MovieClip = c.numChildren > 0 ? c.getChildAt(0) as MovieClip : null;
            if (mc) mc.gotoAndStop(1);
         });
         c.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void
         {
            e.stopPropagation();
            if (onFace != null) onFace(id);
         });
         return c;
      }

      private static function load(faces:IFaceService, id:int, into:Sprite):void
      {
         faces.getFace(id, function(faceId:int, mc:MovieClip):void
         {
            if (mc == null) return;
            mc.gotoAndStop(1);
            fit(mc, CELL - 8);
            mc.x += CELL / 2;
            mc.y += CELL / 2;
            into.addChild(mc);
         });
      }

      /** Scale d to fit a box of `box` px and centre it on (0, 0). */
      public static function fit(d:DisplayObject, box:Number):void
      {
         var b:Rectangle = d.getBounds(d);
         var k:Number = Math.min(1.2, box / Math.max(1, b.width), box / Math.max(1, b.height));
         d.scaleX = d.scaleY = k;
         d.x = -(b.left + b.width / 2) * k;
         d.y = -(b.top + b.height / 2) * k;
      }
   }
}
