package mmo.houseservice
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.berth.BerthInfo;
   import mmo.houseinterfaces.berth.BerthTypes;
   import mmo.houseinterfaces.material.MaterialView;

   /**
    * REBUILT. Moving furniture while decorating: click an item to pick it
    * up (it follows the mouse), click again to put it down; the arrow keys
    * turn it. An item dragged in from the storage is put down where the
    * mouse button is let go. Each frame the berth under the item (floor,
    * wall, ceiling, or outside the room) is passed to MaterialView.onHitBerth,
    * which shows whether it may stand there; MaterialView.endEdit puts it
    * down, or back into the storage when it is outside.
    */
   public class HouseEditor extends EventDispatcher
   {
      public static const GRASP:String = "grasp";
      public static const LAY_DOWN:String = "layDown";

      private var house:IHouse;
      private var editing:Boolean;
      private var current:MaterialView;
      private var dragInto:Boolean;
      private var lastBerth:BerthInfo;
      private var downAt:Point;
      private var ticker:Sprite = new Sprite();

      public function HouseEditor(house:IHouse)
      {
         super();
         this.house = house;
      }

      private function get stage():Stage
      {
         return house && house.container ? house.container.stage : null;
      }

      public function enterEditMode():void
      {
         if (editing || stage == null) return;
         editing = true;
         for each (var v:MaterialView in views()) mark(v, true);
         stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
         stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
         stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
         ticker.addEventListener(Event.ENTER_FRAME, onFrame);
      }

      public function exitEditMode():void
      {
         if (!editing) return;
         if (current != null) layDown();
         editing = false;
         for each (var v:MaterialView in views()) mark(v, false);
         if (stage != null)
         {
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
         }
         ticker.removeEventListener(Event.ENTER_FRAME, onFrame);
      }

      private function views():Array
      {
         var out:Array = [];
         var c:Sprite = house.container;
         for (var i:int = 0; i < c.numChildren; i++)
         {
            if (c.getChildAt(i) is MaterialView) out.push(c.getChildAt(i));
         }
         return out;
      }

      private function mark(v:MaterialView, on:Boolean):void
      {
         v.mouseChildren = !on;
         v.buttonMode = on;
         v.useHandCursor = on;
      }

      /** A view just built from the storage item; grasp: it follows the mouse until put down. */
      public function addView(v:MaterialView, grasp:Boolean):void
      {
         mark(v, editing);
         if (!grasp || !editing) return;
         if (current != null) layDown();
         grasp_(v, true);
      }

      private function grasp_(v:MaterialView, into:Boolean):void
      {
         current = v;
         dragInto = into;
         lastBerth = null;
         downAt = stage ? new Point(stage.mouseX, stage.mouseY) : new Point();
         try { v.startEdit(into); } catch (err:Error) { current = null; return; }
         dispatchEvent(new Event(GRASP));
      }

      private function onMouseDown(e:MouseEvent):void
      {
         if (current != null)
         {
            layDown();
            e.stopImmediatePropagation();
            return;
         }
         var v:MaterialView = e.target as MaterialView;
         if (v == null || v.layoutInfo == null || v.layoutInfo.source.isFix) return;
         e.stopImmediatePropagation();
         grasp_(v, false);
      }

      private function onMouseUp(e:MouseEvent):void
      {
         // Dragged in from the storage with the button held: put it down where it is let go.
         if (current != null && dragInto && downAt != null && Point.distance(downAt, new Point(e.stageX, e.stageY)) > 5) layDown();
      }

      private function onKeyDown(e:KeyboardEvent):void
      {
         if (current == null) return;
         if (e.keyCode == 37 || e.keyCode == 38) current.rotateToLeft();
         else if (e.keyCode == 39 || e.keyCode == 40) current.rotateToRight();
      }

      private function onFrame(e:Event):void
      {
         if (current == null || current.parent == null) return;
         detect();
      }

      private function detect():void
      {
         var b:BerthInfo = hitBerth(current);
         if (b != null && b != lastBerth)
         {
            lastBerth = b;
            current.onHitBerth(b);
         }
      }

      private function hitBerth(v:MaterialView):BerthInfo
      {
         var outside:BerthInfo = house.getBerthByType(BerthTypes.OUTSIDE);
         var at:Point = v.localToGlobal(new Point(0, 0));
         if (outside != null && outside.berth != null)
         {
            var r:Rectangle = v.getBounds(v.stage);
            var corners:Array = [new Point(r.left, r.top), new Point(r.right, r.top), new Point(r.left, r.bottom), new Point(r.right, r.bottom), at];
            for each (var p:Point in corners)
            {
               if (outside.berth.hitTestPoint(p.x, p.y, true)) return outside;
            }
         }
         for each (var b:BerthInfo in house.berthes)
         {
            if (b.type == BerthTypes.OUTSIDE || b.berth == null) continue;
            if (b.berth.hitTestPoint(at.x, at.y, true)) return b;
         }
         return outside;
      }

      private function layDown():void
      {
         var v:MaterialView = current;
         current = null;
         if (v == null) return;
         lastBerth = null;
         try
         {
            if (v.parent != null)
            {
               var b:BerthInfo = hitBerth(v);
               if (b != null) v.onHitBerth(b);
            }
            v.endEdit();
         }
         catch (err:Error) {}
         dispatchEvent(new Event(LAY_DOWN));
      }

      public function dispose():void
      {
         exitEditMode();
         house = null;
         current = null;
      }
   }
}
