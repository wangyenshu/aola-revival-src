package mmo.housestorage
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.decorate.IHouseDecorator;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.houseinterfaces.operate.HouseStorageEvent;
   import mmo.houseinterfaces.operate.StorageTableTypes;
   import mmo.interfaces.changeable.ChangeableCollectionEvent;
   import mmo.interfaces.material.furniture.Furniture;
   import mmo.interfaces.material.furniture.FurnitureTypes;

   /** REBUILT. The storage panel, bound to the storage symbol of the later house/housestorage art. */
   public class HouseStorage extends Sprite
   {
      private static const PAGE:int = 11;

      public var btnNext:SimpleButton;
      public var btnPrev:SimpleButton;
      public var emptyTip:MovieClip;
      public var tableBar:TableBar;
      public var view0:ItemView;
      public var view1:ItemView;
      public var view2:ItemView;
      public var view3:ItemView;
      public var view4:ItemView;
      public var view5:ItemView;
      public var view6:ItemView;
      public var view7:ItemView;
      public var view8:ItemView;
      public var view9:ItemView;
      public var view10:ItemView;

      private var house:IHouse;
      private var decorators:Array = [];
      private var views:Array = [];
      private var page:int;
      private var pages:int = 1;
      private var pressed:ItemView;
      private var pressedAt:Point;
      private var listening:Stage;

      public function HouseStorage()
      {
         super();
      }

      public function setUp(h:IHouse, list:Array):void
      {
         house = h;
         decorators = list || [];
         for (var i:int = 0; i < PAGE; i++)
         {
            var v:ItemView = this["view" + i] as ItemView;
            if (v) views.push(v);
         }
         if (tableBar)
         {
            tableBar.addEventListener(TableBar.onSelectChanged, onType);
            tableBar.selectType = StorageTableTypes.All;
         }
         if (btnPrev) btnPrev.addEventListener(MouseEvent.CLICK, onPrev);
         if (btnNext) btnNext.addEventListener(MouseEvent.CLICK, onNext);
         if (emptyTip)
         {
            emptyTip.visible = false;
            var go:SimpleButton = emptyTip.getChildByName("btnGo") as SimpleButton;
            if (go) go.visible = false;
         }
         for each (var d:IHouseDecorator in decorators)
         {
            d.addEventListener(ChangeableCollectionEvent.onAddObject, onChanged);
            d.addEventListener(ChangeableCollectionEvent.onRemoveObject, onChanged);
         }
      }

      public function show():void
      {
         var top:Sprite = Object(house).foreGround as Sprite;
         if (top != null) top.addChild(this);
         visible = true;
         refresh();
         if (stage != null && listening == null)
         {
            listening = stage;
            listening.addEventListener(MouseEvent.MOUSE_DOWN, onDown, true);
            listening.addEventListener(MouseEvent.MOUSE_MOVE, onMove, true);
            listening.addEventListener(MouseEvent.MOUSE_UP, onUp, true);
         }
      }

      public function hide():void
      {
         visible = false;
         unlisten();
         if (parent != null) parent.removeChild(this);
      }

      private function unlisten():void
      {
         if (listening == null) return;
         listening.removeEventListener(MouseEvent.MOUSE_DOWN, onDown, true);
         listening.removeEventListener(MouseEvent.MOUSE_MOVE, onMove, true);
         listening.removeEventListener(MouseEvent.MOUSE_UP, onUp, true);
         listening = null;
      }

      public function refresh():void
      {
         showItems();
      }

      /** Items of the chosen kind that are not all placed (main-home furniture only). */
      private function items(type:int):Array
      {
         var out:Array = [];
         for each (var d:IHouseDecorator in decorators)
         {
            var list:Array = (d.getStorageItems() || []).concat();
            list.sortOn(["materialId"], [Array.NUMERIC | Array.DESCENDING]);
            for each (var w:UserMaterialWrap in list)
            {
               var f:Furniture = w.material as Furniture;
               if (w.available <= 0) continue;
               if (f != null && f.place != FurnitureTypes.MAINHOUSEFURNITURE) continue;
               if (type != StorageTableTypes.All && w.storageTableType != type) continue;
               out.push(w);
            }
         }
         return out;
      }

      private function showItems():void
      {
         var type:int = tableBar ? tableBar.selectType : StorageTableTypes.All;
         var list:Array = items(type);
         pages = Math.max(1, Math.ceil(list.length / PAGE));
         page = Math.min(page, pages - 1);
         if (emptyTip) emptyTip.visible = list.length == 0 && type == StorageTableTypes.All;
         for (var i:int = 0; i < views.length; i++)
         {
            ItemView(views[i]).data = list[page * PAGE + i] as UserMaterialWrap;
         }
         if (btnPrev) btnPrev.alpha = page > 0 ? 1 : 0.4;
         if (btnNext) btnNext.alpha = page < pages - 1 ? 1 : 0.4;
      }

      private function onType(e:Event):void
      {
         page = 0;
         showItems();
      }

      private function onPrev(e:MouseEvent):void
      {
         if (page > 0)
         {
            page--;
            showItems();
         }
      }

      private function onNext(e:MouseEvent):void
      {
         if (page < pages - 1)
         {
            page++;
            showItems();
         }
      }

      private function onChanged(e:ChangeableCollectionEvent):void
      {
         if (visible && parent != null) showItems();
      }

      // ───── taking an item out: a click puts it at its usual spot, a drag carries it ─────

      private function onDown(e:MouseEvent):void
      {
         if (!mouseChildren) return;
         var v:ItemView = e.target as ItemView;
         pressed = v != null && v.data != null && views.indexOf(v) >= 0 ? v : null;
         pressedAt = new Point(e.stageX, e.stageY);
      }

      private function onMove(e:MouseEvent):void
      {
         if (pressed == null) return;
         if (Math.abs(e.stageX - pressedAt.x) > 10 || Math.abs(e.stageY - pressedAt.y) > 10)
         {
            var w:UserMaterialWrap = pressed.data;
            pressed = null;
            dispatchEvent(new HouseStorageEvent(HouseStorageEvent.onDragMaterial, {userMaterialWrap: w, point: new Point(e.stageX, e.stageY)}));
         }
      }

      private function onUp(e:MouseEvent):void
      {
         if (pressed == null) return;
         var w:UserMaterialWrap = pressed.data;
         pressed = null;
         dispatchEvent(new HouseStorageEvent(HouseStorageEvent.onChooseMaterial, {userMaterialWrap: w}));
      }

      public function dispose():void
      {
         unlisten();
         for each (var d:IHouseDecorator in decorators)
         {
            d.removeEventListener(ChangeableCollectionEvent.onAddObject, onChanged);
            d.removeEventListener(ChangeableCollectionEvent.onRemoveObject, onChanged);
         }
         for each (var v:ItemView in views) v.data = null;
         if (tableBar) tableBar.removeEventListener(TableBar.onSelectChanged, onType);
         decorators = [];
         views = [];
         house = null;
         if (parent != null) parent.removeChild(this);
      }
   }
}
