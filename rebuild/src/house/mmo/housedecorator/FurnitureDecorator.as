package mmo.housedecorator
{
   import flash.geom.Point;
   import mmo.common.dialog.NewDialog;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.framework.comm.house.UserFurnitureInfoClient;
   import mmo.houseinterfaces.IHouse;
   import mmo.houseinterfaces.IHouseService;
   import mmo.houseinterfaces.decorate.HouseDecoratorEvent;
   import mmo.houseinterfaces.decorate.IFurnitureDecorator;
   import mmo.houseinterfaces.material.HouseItemTypes;
   import mmo.houseinterfaces.material.MaterialLayoutInfo;
   import mmo.houseinterfaces.material.MaterialSketch;
   import mmo.houseinterfaces.material.MaterialView;
   import mmo.houseinterfaces.material.UserMaterialWrap;
   import mmo.interfaces.IService;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.changeable.ChangeableCollection;
   import mmo.interfaces.changeable.ChangeableCollectionEvent;
   import mmo.interfaces.material.Material;
   import mmo.interfaces.material.furniture.Furniture;
   import mmo.interfaces.material.furniture.IFurnitureService;
   import mmo.interfaces.material.furniture.UserFurniture;
   import mmo.revival.RLog;

   /**
    * REBUILT house/furnituredecorator (ServiceConfig "FurnitureDecorator",
    * the first of HouseService's decorators): the furniture of a home. The
    * 2013 module is lost; written against the 2013 IFurnitureDecorator and
    * UserFurnitureInfoClient:
    *
    *   63_1 {un, hid}         -> {infos: [{fid, key, x, y, ag, ex}]}  what stands where
    *   63_2 {hid, changes}    -> {result}   changes: [{fid, key, x, y, a, exd, op}],
    *                                        op = MaterialLayoutState (1 added, 2 moved, 3 removed)
    *   63_3 {hid, nid}        -> {result, nid}  another house type: everything back into storage
    *
    * The owner's items come from the 2013 FurnitureService (with how many of
    * each are placed: "usedUp"); a visitor sees only what is placed.
    */
   public class FurnitureDecorator extends ChangeableCollection implements IFurnitureDecorator
   {
      private var houseService:IHouseService;
      private var house:IHouse;
      private var furnitureService:IFurnitureService;
      private var infos:Array = [];
      private var views:Array = [];

      public function FurnitureDecorator()
      {
         super();
      }

      public function getInstance():IService
      {
         return this;
      }

      private function get houseId():int
      {
         return houseService.houseLoader.houseInfo.currentHouseId;
      }

      public function preDecorate(hs:IHouseService):void
      {
         houseService = hs;
         house = hs.house;
         furnitureService = ServiceContainer.getService(IFurnitureService) as IFurnitureService;
         furnitureService.addEventListener(ChangeableCollectionEvent.onAddObject, onBoughtFurniture);
         var sc:SocketClient = SocketClient.instance;
         var onInfos:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(UserFurnitureInfoClient.onGetUserHouseFurnitureInfos, onInfos);
            infos = (e.params.infos as Array) || [];
            dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onPreDecorated, {}));
         };
         sc.addEventListener(UserFurnitureInfoClient.onGetUserHouseFurnitureInfos, onInfos);
         UserFurnitureInfoClient.instance.getUserHouseFurnitureInfos(hs.houseLoader.houseInfo.owner, houseId);
      }

      public function decorate():void
      {
         clear();
         if (houseService.houseLoader.isMyHouse)
         {
            for each (var uf:UserFurniture in furnitureService.getMyMaterials())
            {
               var w:UserFurnitureWrap = new UserFurnitureWrap(uf, this);
               addObject(w);
               for each (var info:Object in infos)
               {
                  if (int(info.fid) == w.materialId) place(w, info);
               }
            }
         }
         else
         {
            for each (var o:Object in infos)
            {
               var m:Material = furnitureService.getMaterialById(int(o.fid));
               if (m == null) continue;
               place(new UserFurnitureWrap(new UserFurniture(m, 1, 1), this), o);
            }
         }
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onDecorated, {}));
      }

      /** Put an item where the server says it stands (or at its usual spot if that is off the screen). */
      private function place(w:UserMaterialWrap, info:Object):void
      {
         var x:int = int(info.x), y:int = int(info.y);
         if (x < 0 || x > 960 || y < 0 || y > 560) x = y = int.MAX_VALUE;
         var layout:MaterialLayoutInfo = w.buildLayoutInfo(houseId, int(info.key), x, y, int(info.ag), info.ex);
         var v:FurnitureView = new FurnitureView(layout);
         v.show(house);
         views.push(v);
      }

      /** From the storage into the room. A house type asks first: it empties the room. */
      public function buildView(w:UserMaterialWrap, at:Point):MaterialView
      {
         var f:Furniture = w.material as Furniture;
         if (f != null && f.type == HouseItemTypes.HOUSE_BACKGROUND)
         {
            askChangeHouse(f);
            return null;
         }
         var layout:MaterialLayoutInfo = w.getNewLayoutInfo(houseId);
         if (layout == null) return null;
         layout.x = at.x;
         layout.y = at.y;
         var v:FurnitureView = new FurnitureView(layout);
         v.show(house);
         views.push(v);
         if (w.available == 0) dispatchEvent(new ChangeableCollectionEvent(ChangeableCollectionEvent.onRemoveObject, w, {}));
         return v;
      }

      /** Back into the storage (dropped outside the room). */
      public function unUse(v:MaterialView):void
      {
         var i:int = views.indexOf(v);
         if (i >= 0) views.splice(i, 1);
         var w:UserMaterialWrap = v.layoutInfo.source;
         w.unUse(v.layoutInfo);
         if (w.available == 1) dispatchEvent(new ChangeableCollectionEvent(ChangeableCollectionEvent.onAddObject, w, {}));
      }

      public function getStorageItems():Array
      {
         return getObjects();
      }

      public function getSketch(w:UserMaterialWrap, width:int, height:int):MaterialSketch
      {
         return new FurnitureSketch(w, width, height);
      }

      public function get getViews():Array
      {
         return views;
      }

      // ───── saving ─────

      public function save():void
      {
         var changes:Array = [];
         for each (var w:UserMaterialWrap in getObjects())
         {
            for each (var l:MaterialLayoutInfo in w.getChanges())
            {
               changes.push({fid: w.materialId, key: l.key, x: l.x, y: l.y, a: l.angle, exd: l.extData, op: l.state});
            }
         }
         if (changes.length == 0)
         {
            saved(true);
            return;
         }
         var sc:SocketClient = SocketClient.instance;
         var onSaved:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(UserFurnitureInfoClient.onSaveHouseFurnitureInfos, onSaved);
            var r:int = int(e.params.result);
            if (r != 1) NewDialog.showFailMessage(r == -4 ? "保存时错误，家具数量不够！" : "保存装扮时出错了，请再试一次。");
            saved(r == 1);
         };
         sc.addEventListener(UserFurnitureInfoClient.onSaveHouseFurnitureInfos, onSaved);
         UserFurnitureInfoClient.instance.saveHouseFurnitureInfos(houseId, changes);
      }

      private function saved(ok:Boolean):void
      {
         if (ok)
         {
            for each (var w:UserMaterialWrap in getObjects()) w.acceptChanges();
         }
         else
         {
            rebuild();
         }
         dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onSaved, {result: ok}));
      }

      /** Throw away unsaved moves: build the room again from what the server holds. */
      private function rebuild():void
      {
         disposeViews();
         for each (var w:UserMaterialWrap in getObjects()) w.dispose();
         decorate();
      }

      // ───── another house type ─────

      private function askChangeHouse(f:Furniture):void
      {
         NewDialog.getCofirmDialog("你更换房型后，家里所有家具将被摆到仓库内，需要重新布置家，你确认更换吗？", function(d:ModalDialog):void
         {
            d.addEventListener(ModalDialogEvent.OK, function(e:ModalDialogEvent):void { resetHouse(houseService.houseLoader.houseInfo.mainHouseId, f.id); });
            d.show();
         }, null, FurnitureViews.instance.getSketch(f.id));
      }

      public function resetHouse(oldId:int, newId:int):void
      {
         var sc:SocketClient = SocketClient.instance;
         var onChanged:Function = function(e:SocketClientEvent):void
         {
            sc.removeEventListener(UserFurnitureInfoClient.onChangeHouse, onChanged);
            if (int(e.params.result) != 1)
            {
               NewDialog.showFailMessage("更换小屋失败，请重试！");
               return;
            }
            for each (var w:UserMaterialWrap in getObjects())
            {
               if (w is UserFurnitureWrap) UserFurnitureWrap(w).clearOnResetHouse(int(e.params.nid));
            }
            dispatchEvent(new HouseDecoratorEvent(HouseDecoratorEvent.onResetHouse, e.params));
            houseService.houseLoader.loadHouse(houseService.houseLoader.houseInfo.owner, true, 1);
         };
         sc.addEventListener(UserFurnitureInfoClient.onChangeHouse, onChanged);
         UserFurnitureInfoClient.instance.changeHouse(oldId, newId);
      }

      // ───── bought while at home ─────

      private function onBoughtFurniture(e:ChangeableCollectionEvent):void
      {
         var uf:UserFurniture = e.object as UserFurniture;
         if (uf == null || houseService == null || !houseService.houseLoader.isMyHouse) return;
         for each (var w:UserMaterialWrap in getObjects())
         {
            if (w.materialId == uf.materialId) return;
         }
         var nw:UserFurnitureWrap = new UserFurnitureWrap(uf, this);
         addObject(nw);
      }

      public function close():void
      {
         if (furnitureService) furnitureService.removeEventListener(ChangeableCollectionEvent.onAddObject, onBoughtFurniture);
         disposeViews();
         for each (var w:UserMaterialWrap in getObjects())
         {
            try { w.dispose(); } catch (err:Error) {}
         }
         clear();
         furnitureService = null;
         house = null;
         houseService = null;
         infos = [];
      }

      private function disposeViews():void
      {
         for each (var v:MaterialView in views) v.dispose();
         views = [];
      }
   }
}
